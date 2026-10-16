#!/usr/bin/env python3
"""
LIMET Launcher — local web UI to operate a LIMET project.

Serves a single page (launcher.html) and a /api/run endpoint that runs the
LIMET scripts (limet + limet-index) for the requested action: create (init),
re-index (update), status, remove. 100% local: binds to 127.0.0.1, no external
calls, no dependencies beyond the stdlib.

Usage:
    python limet-launcher.py [--port 8799]
"""
import json
import os
import shutil
import subprocess
import sys
import threading
import time
import webbrowser
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse, parse_qs
import re
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
HOST = "127.0.0.1"
DEFAULT_PORT = 8799
IS_WIN = os.name == "nt"

sys.path.insert(0, HERE)
import limet_related  # noqa: E402

ACTIONS = ("create", "update", "status", "remove", "instructions", "adddocs", "related", "unrelate", "createrelated")

QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")

CREATE_NO_WINDOW = 0x08000000 if IS_WIN else 0

# --- running-job tracking (for the "Stop" button) ------------------------------------------------
# One job at a time, local single-user tool: a global slot is enough. Guarded by RUN_LOCK since
# /api/run (writer) and /api/stop (reader/killer) run on different threads (ThreadingHTTPServer).
RUN_LOCK = threading.Lock()
JOB_LOCK = threading.Lock()
RUNNING = {"proc": None, "stop_requested": False}


def _popen_tree(argv):
    """Start argv in its own process group/job (Windows) or session (POSIX) so the whole tree
    (e.g. powershell -> graphify / python ingest_docs.py) can be killed together on Stop."""
    kwargs = dict(
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
        encoding="utf-8", errors="replace", bufsize=1, env=_subprocess_env(),
    )
    if IS_WIN:
        kwargs["creationflags"] = CREATE_NO_WINDOW | subprocess.CREATE_NEW_PROCESS_GROUP
    else:
        kwargs["preexec_fn"] = os.setsid
    return subprocess.Popen(argv, **kwargs)


def _kill_tree(proc):
    """Best-effort kill of the whole process tree started by _popen_tree."""
    if proc is None or proc.poll() is not None:
        return
    try:
        if IS_WIN:
            subprocess.run(["taskkill", "/PID", str(proc.pid), "/T", "/F"],
                            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        else:
            os.killpg(os.getpgid(proc.pid), 15)  # SIGTERM
    except Exception:
        pass


def _subprocess_env():
    env = os.environ.copy()
    env["PYTHONUNBUFFERED"] = "1"
    return env


def slugify(name):
    return re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")


def _get_ok(url, timeout=3):
    try:
        urllib.request.urlopen(url, timeout=timeout).read()
        return True
    except Exception:
        return False


def _collection_exists(name):
    return _get_ok(f"{QDRANT_URL}/collections/{name}")


DEFAULT_DOCS_DIR = "docs-limet"


def _is_limet_owned_docs(path):
    """Tell a LIMET-generated docs/ apart from a project's own docs/. Only LIMET writes these."""
    return (os.path.isdir(os.path.join(path, "_templates"))
            or os.path.isfile(os.path.join(path, "architecture", "GRAPH_REPORT.md"))
            or os.path.isfile(os.path.join(path, "NON_TECHNICAL_SUMMARY.md")))


def _docs_dir(slug, path, cerebro):
    """LIMET's docs folder for this project. Mirrors limet-index's resolution order: CEREBRO
    registry (keeps pre-convention projects working), then docs-limet/, then a docs/ that looks
    LIMET-owned, then docs-limet/."""
    if cerebro:
        reg_file = os.path.join(cerebro, "projects.json")
        if os.path.exists(reg_file):
            try:
                with open(reg_file, encoding="utf-8") as f:
                    entry = json.load(f).get(slug, {})
                for d in entry.get("docs", []):
                    if os.path.isdir(d):
                        return d
            except Exception:
                pass
    default_dir = os.path.join(path, DEFAULT_DOCS_DIR)
    if os.path.isdir(default_dir):
        return default_dir
    legacy = os.path.join(path, "docs")
    if os.path.isdir(legacy) and _is_limet_owned_docs(legacy):
        return legacy
    return default_dir


def script_path(name):
    return os.path.join(HERE, name + (".ps1" if IS_WIN else ".sh"))


def _read_env_file(path):
    """Read KEY=VALUE pairs from a project-local .env file (stdlib only)."""
    values = {}
    env_file = os.path.join(path, ".env")
    if not os.path.isfile(env_file):
        return values
    try:
        with open(env_file, encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith("#") or "=" not in line:
                    continue
                k, v = line.split("=", 1)
                values[k.strip()] = v.strip().strip('"').strip("'")
    except Exception:
        pass
    return values


def _resolve_cerebro_home(path, explicit=""):
    """CEREBRO_HOME: explicit arg > process env > project .env."""
    if explicit:
        return explicit
    env = os.environ.get("CEREBRO_HOME", "")
    if env:
        return env
    return _read_env_file(path).get("CEREBRO_HOME", "")


def read_html():
    with open(os.path.join(HERE, "launcher.html"), "r", encoding="utf-8") as f:
        return f.read()


# --- command building --------------------------------------------------------------------------


def _index_cmd(sub, path, cerebro_home, lang="en", workspace=False, force=False, prune=False, skip_graph=False):
    """Build the limet-index command (init/update/status/remove) for this platform."""
    if IS_WIN:
        cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
               script_path("limet-index"), sub, "-ProjectPath", path]
        if sub in ("init", "instructions", "update"):
            cmd += ["-Lang", lang]
            if workspace:
                cmd += ["-Workspace"]
        if sub == "update":
            if force:
                cmd += ["-Force"]
            if prune:
                cmd += ["-Prune"]
            if skip_graph:
                cmd += ["-SkipGraph"]
        if cerebro_home:
            cmd += ["-CerebroHome", cerebro_home]
        return cmd
    cmd = ["bash", script_path("limet-index"), sub, "--project-path", path]
    if sub in ("init", "instructions", "update"):
        cmd += ["--lang", lang]
        if workspace:
            cmd += ["--workspace"]
    if sub == "update":
        if force:
            cmd += ["--force"]
        if prune:
            cmd += ["--prune"]
        if skip_graph:
            cmd += ["--skip-graph"]
    if cerebro_home:
        cmd += ["--cerebro-home", cerebro_home]
    return cmd


def build_commands(params):
    """Return the ordered list of (label, argv) for the requested action."""
    action = params.get("action", "create")
    path = params["path"]
    lang = params.get("lang", "en")
    workspace = bool(params.get("workspace"))
    if action in ("update", "instructions", "adddocs"):
        workspace = workspace or os.path.isdir(os.path.join(path, "limet-workspace"))
    context = bool(params.get("context"))
    force = bool(params.get("force"))
    prune = bool(params.get("prune"))
    cerebro_home = _resolve_cerebro_home(path, params.get("cerebro_home") or "")

    if action == "instructions":
        return [("Generate instruction files", _index_cmd("instructions", path, cerebro_home, lang, workspace))]
    if action == "adddocs":
        # Auto-decide bootstrap vs incremental re-index: if the project's CEREBRO collection
        # doesn't exist yet, run the full "create" sequence (LIMET init + Graphify/CEREBRO init)
        # so a single click works both for a brand-new project and for one already set up.
        # Otherwise, "update" already does everything needed in one pass: incremental Qdrant
        # ingest (deterministic upsert, no duplicates), `graphify update .`, and regeneration of
        # CLAUDE.md / copilot-instructions.md — this is what used to require the separate
        # "Genera documentazione" button, now folded in here.
        slug = slugify(os.path.basename(path.rstrip("\\/")) or path)
        if not _collection_exists(f"CRB_{slug}"):
            bootstrap_params = dict(params, action="create", context=True, workspace=workspace)
            return build_commands(bootstrap_params)
        # Only docs changed: skip the (slow) Graphify code-graph refresh; it stays on "Re-index".
        return [("Indicizzazione documenti + istruzioni",
                 _index_cmd("update", path, cerebro_home, lang=lang, workspace=workspace,
                            force=force, prune=prune, skip_graph=True))]
    if action == "update":
        return [("LIMET re-index", _index_cmd("update", path, cerebro_home, lang=lang, workspace=workspace, force=force, prune=prune))]
    if action == "status":
        return [("LIMET status", _index_cmd("status", path, cerebro_home))]
    if action == "remove":
        return [("LIMET remove", _index_cmd("remove", path, cerebro_home))]

    # action == "create" (default)
    cmds = []
    if IS_WIN:
        base = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File"]
        init = base + [script_path("limet"), "init", "-ProjectPath", path, "-Lang", lang]
        if workspace:
            init += ["-Workspace"]
        cmds.append(("LIMET init", init))
    else:
        init = ["bash", script_path("limet"), "init", "--project-path", path, "--lang", lang]
        if workspace:
            init += ["--workspace"]
        cmds.append(("LIMET init", init))

    if context:
        cmds.append(("LIMET context (CEREBRO RAG + Graphify)",
                     _index_cmd("init", path, cerebro_home, lang, workspace)))
    return cmds


class Handler(BaseHTTPRequestHandler):
    server_version = "LimetLauncher/1.0"

    def log_message(self, fmt, *args):
        sys.stderr.write("[launcher] " + (fmt % args) + "\n")

    def _json(self, obj, code=200):
        data = json.dumps(obj).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def _start_stream(self):
        self._client_gone = False
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Transfer-Encoding", "chunked")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

    def _chunk(self, data):
        if not data:
            return
        # Once the browser is gone (tab closed, page reloaded), keep draining the
        # subprocess output instead of raising: an unread stdout pipe fills up and
        # freezes the command mid-run.
        if getattr(self, "_client_gone", False):
            return
        if isinstance(data, str):
            data = data.encode("utf-8")
        try:
            self.wfile.write(("%x\r\n" % len(data)).encode("ascii"))
            self.wfile.write(data)
            self.wfile.write(b"\r\n")
            self.wfile.flush()
        except OSError:
            self._client_gone = True
            sys.stderr.write("[launcher] client disconnesso: output non piu' inviato, "
                             "il comando prosegue fino al termine\n")

    def _end_stream(self):
        if getattr(self, "_client_gone", False):
            return
        try:
            self.wfile.write(b"0\r\n\r\n")
            self.wfile.flush()
        except OSError:
            pass

    def _handle_related(self, action, params):
        paths = params.get("paths")
        cerebro = _resolve_cerebro_home((paths[0] if isinstance(paths, list) and paths and isinstance(paths[0], str) else ""),
                                        params.get("cerebro_home") or "")
        self._start_stream()
        ok = True
        try:
            if not cerebro:
                raise limet_related.RelatedError("CEREBRO_HOME non impostato")
            if params.get("dry_run"):
                self._chunk("\n=== Verifica progetti correlati ===\n")
                problems = limet_related.check(cerebro, paths)
                if problems:
                    raise limet_related.RelatedError("\n".join(problems))
                self._chunk("Percorsi validi e registrati. Qdrant/collection verificati al momento del collegamento.\n")
            elif action == "related":
                self._chunk("\n=== Collega progetti correlati ===\n")
                limet_related.link(cerebro, paths, QDRANT_URL, log=lambda m: self._chunk(m + "\n"))
            else:
                self._chunk("\n=== Scollega progetti correlati ===\n")
                limet_related.unlink(cerebro, paths, log=lambda m: self._chunk(m + "\n"))
            self._chunk("\nFatto.\n")
        except limet_related.RelatedError as e:
            self._chunk("\n[ERRORE] %s\n" % e)
            ok = False
        except Exception as e:
            self._chunk("\n[ERRORE] %s\n" % e)
            ok = False
        self._end_stream()
        return ok

    def _handle_createrelated(self, params):
        """Create every listed project (standard Crea) and then link them all together."""
        paths = params.get("paths")
        self._start_stream()
        ok = True
        with RUN_LOCK:
            RUNNING["stop_requested"] = False
            RUNNING["proc"] = None
        try:
            if not isinstance(paths, list) or not all(isinstance(p, str) for p in paths):
                raise limet_related.RelatedError("elenco percorsi non valido")
            paths = [p.strip() for p in paths if p.strip()]
            if len(paths) < 2:
                raise limet_related.RelatedError("servono almeno 2 progetti (uno per riga)")
            if len(paths) > limet_related.MAX_PROJECTS:
                raise limet_related.RelatedError("troppi progetti (max %d)" % limet_related.MAX_PROJECTS)
            if not params.get("context"):
                raise limet_related.RelatedError('attiva "Strumenti di contesto": serve la registrazione in CEREBRO per collegare i progetti')
            cerebro = _resolve_cerebro_home(paths[0], params.get("cerebro_home") or "")
            if not cerebro:
                raise limet_related.RelatedError("CEREBRO_HOME non impostato")
            slugs = {}
            for p in paths:
                s = slugify(os.path.basename(p.rstrip("\\/")) or p)
                if s in slugs:
                    raise limet_related.RelatedError("cartelle finali con lo stesso nome (slug '%s'): %s e %s" % (s, slugs[s], p))
                slugs[s] = p
            registry = {}
            reg_file = os.path.join(cerebro, "projects.json")
            if os.path.isfile(reg_file):
                with open(reg_file, encoding="utf-8-sig") as f:
                    registry = json.load(f)
            todo = []
            for p in paths:
                s = slugify(os.path.basename(p.rstrip("\\/")) or p)
                entry = registry.get(s) if isinstance(registry, dict) else None
                if entry is not None:
                    if limet_related.norm_path(str(entry.get("root", ""))) != limet_related.norm_path(p):
                        raise limet_related.RelatedError("slug '%s' già registrato per un'altra cartella: %s" % (s, entry.get("root")))
                    self._chunk("Già registrato, non lo ricreo: %s\n" % p)
                else:
                    todo.append(p)
            for p in todo:
                for label, argv in build_commands({"action": "create", "path": p, "lang": params.get("lang", "en"),
                                                   "workspace": False, "context": True, "cerebro_home": cerebro}):
                    with RUN_LOCK:
                        if RUNNING["stop_requested"]:
                            ok = False
                    if not ok:
                        break
                    self._chunk("\n=== %s — %s ===\n" % (os.path.basename(p.rstrip("\\/")), label))
                    proc = _popen_tree(argv)
                    with RUN_LOCK:
                        RUNNING["proc"] = proc
                    for line in proc.stdout:
                        self._chunk(line)
                    proc.wait()
                    with RUN_LOCK:
                        RUNNING["proc"] = None
                        stopped = RUNNING["stop_requested"]
                    if stopped:
                        self._chunk("\n[FERMATO] interrotto su richiesta dell'utente.\n")
                        ok = False
                        break
                    if proc.returncode != 0:
                        self._chunk("\n[ERRORE] '%s' exited with code %s — stopped. I progetti successivi non sono stati creati.\n" % (label, proc.returncode))
                        ok = False
                        break
                if not ok:
                    break
            if ok:
                self._chunk("\n=== Collega progetti correlati ===\n")
                limet_related.link(cerebro, paths, QDRANT_URL, log=lambda m: self._chunk(m + "\n"))
                self._chunk("\nFatto. Progetti creati e collegati.\n")
        except Exception as e:
            self._chunk("\n[ERRORE] %s\n" % e)
            ok = False
        finally:
            with RUN_LOCK:
                RUNNING["proc"] = None
        self._end_stream()
        return ok

    def do_GET(self):
        parsed = urlparse(self.path)
        if parsed.path == "/":
            html = read_html().encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "text/html; charset=utf-8")
            self.send_header("Content-Length", str(len(html)))
            self.end_headers()
            self.wfile.write(html)
        elif parsed.path == "/api/info":
            cerebro_home = os.environ.get("CEREBRO_HOME", "")
            graphify = shutil.which("graphify") is not None
            self._json({
                "cerebro_home": cerebro_home,
                "graphify": graphify,
                "platform": "win" if IS_WIN else "unix",
            })
        elif parsed.path == "/api/check":
            q = parse_qs(parsed.query)
            path = q.get("path", [""])[0].strip()
            cerebro = q.get("cerebro", [""])[0].strip()
            if not path:
                self._json({"error": "path required"}, 400)
                return
            cerebro = _resolve_cerebro_home(path, cerebro)
            slug = slugify(os.path.basename(path.rstrip("\\/")) or path)
            collection = "CRB_" + slug
            registered = False
            root_matches = None
            if cerebro:
                reg_file = os.path.join(cerebro, "projects.json")
                if os.path.exists(reg_file):
                    try:
                        with open(reg_file, encoding="utf-8-sig") as f:
                            _reg = json.load(f)
                        registered = slug in _reg
                        _root = (_reg.get(slug) or {}).get("root")
                        if registered and _root:
                            root_matches = limet_related.norm_path(_root) == limet_related.norm_path(path)
                    except Exception:
                        registered = False
            qdrant_up = _get_ok(f"{QDRANT_URL}/collections")
            ollama_up = _get_ok(OLLAMA_URL)
            docs_dir = _docs_dir(slug, path, cerebro)
            existing_docs = []
            if os.path.isdir(docs_dir):
                for root, dirs, files in os.walk(docs_dir):
                    dirs[:] = [d for d in dirs if d != "_templates"]
                    for fn in files:
                        if fn.lower().endswith((".md", ".txt", ".pdf", ".epub", ".docx", ".xlsx", ".pptx", ".html", ".htm")):
                            existing_docs.append(os.path.relpath(os.path.join(root, fn), docs_dir))
            existing_docs = sorted(existing_docs)
            self._json({
                "slug": slug,
                "collection": collection,
                "registered": registered,
                "root_matches": root_matches,
                "qdrant_up": qdrant_up,
                "ollama_up": ollama_up,
                "collection_created": _collection_exists(collection) if qdrant_up else False,
                "docs_dir": docs_dir,
                "docs_count": len(existing_docs),
                "existing_docs": existing_docs[:20],
                "cerebro_home": cerebro,
            })
        elif parsed.path == "/api/shutdown":
            self._json({"ok": "shutting down"})

            def _shutdown():
                time.sleep(0.3)
                os._exit(0)
            threading.Thread(target=_shutdown).start()
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)
        if parsed.path == "/api/stop":
            with RUN_LOCK:
                proc = RUNNING.get("proc")
                RUNNING["stop_requested"] = True
            if proc is not None and proc.poll() is None:
                _kill_tree(proc)
                self._json({"stopped": True})
            else:
                self._json({"stopped": False, "message": "Nessun processo in esecuzione."})
            return
        if parsed.path != "/api/run":
            self.send_response(404)
            self.end_headers()
            return

        try:
            length = int(self.headers.get("Content-Length") or 0)
            body = self.rfile.read(length).decode("utf-8")
            params = json.loads(body)
        except Exception as e:
            self._json({"error": "bad request: %s" % e}, 400)
            return

        # One mutating job at a time (the registry is shared by every action).
        if not JOB_LOCK.acquire(blocking=False):
            self._json({"error": "un'altra operazione è in corso: attendi che termini"}, 409)
            return
        try:
            self._run_job(params)
        finally:
            JOB_LOCK.release()

    def _run_job(self, params):
        path = (params.get("path") or "").strip()
        action = params.get("action") or "create"
        if action not in ACTIONS:
            self._json({"error": "unknown action: %s" % action}, 400)
            return
        if action in ("related", "unrelate"):
            self._handle_related(action, params)
            return
        if action == "createrelated":
            self._handle_createrelated(params)
            return
        if not path:
            self._json({"error": "project path is required"}, 400)
            return

        done_msg = {
            "create": "Fatto. Il progetto è pronto.",
            "update": "Fatto. Indici aggiornati.",
            "status": "Fatto.",
            "remove": "Fatto. Progetto rimosso dal registry (la collection Qdrant resta).",
            "instructions": "Fatto. Istruzioni generate (CLAUDE.md + copilot-instructions.md) — l'agente le userà per creare/aggiornare i documenti approfonditi.",
            "adddocs": "Fatto. Documenti aggiunti e indicizzati.",
        }[action]

        self._start_stream()
        ok = True
        with RUN_LOCK:
            RUNNING["stop_requested"] = False
            RUNNING["proc"] = None
        try:
            if action == "remove":
                # Drop this project's collection from related projects before unregistering it.
                # A failure here is fatal: removing anyway would leave dangling links in the peers.
                _rc = _resolve_cerebro_home(path, params.get("cerebro_home") or "")
                if _rc:
                    _rslug = slugify(os.path.basename(path.rstrip("\\/")) or path)
                    _reg = os.path.join(_rc, "projects.json")
                    try:
                        _in_registry = False
                        if os.path.isfile(_reg):
                            with open(_reg, encoding="utf-8-sig") as _f:
                                _in_registry = _rslug in json.load(_f)
                        if _in_registry:
                            self._chunk("\n=== Scollega correlati ===\n")
                            limet_related.unlink(_rc, [path], log=lambda m: self._chunk(m + "\n"))
                    except Exception as e:
                        self._chunk("\n[ERRORE] scollegamento correlati fallito, rimozione annullata: %s\n" % e)
                        self._end_stream()
                        return
            if action == "adddocs":
                _slug = slugify(os.path.basename(path.rstrip("\\/")) or path)
                _cerebro = _resolve_cerebro_home(path, params.get("cerebro_home") or "")
                docs_dir = _docs_dir(_slug, path, _cerebro)
                category = (params.get("category") or "").strip().replace("\\", "/").strip("/")
                if category:
                    parts = [p for p in category.split("/") if p]
                    if any(p in (".", "..") or ":" in p for p in parts):
                        self._chunk("\n[ERRORE] Sotto-cartella non valida: usa un percorso relativo dentro docs/.\n")
                        return
                    docs_dir = os.path.join(docs_dir, *parts)
                os.makedirs(docs_dir, exist_ok=True)
                copied = 0
                for d in (params.get("docs") or []):
                    d = d.strip()
                    if not d or not os.path.exists(d):
                        continue
                    if os.path.isdir(d):
                        for root, _dirs, files in os.walk(d):
                            for fn in files:
                                src = os.path.join(root, fn)
                                rel = os.path.relpath(src, d)
                                dst = os.path.join(docs_dir, rel)
                                os.makedirs(os.path.dirname(dst), exist_ok=True)
                                shutil.copy2(src, dst)
                                copied += 1
                    else:
                        shutil.copy2(d, os.path.join(docs_dir, os.path.basename(d)))
                        copied += 1
                self._chunk("\nCopiati %d file in %s\n" % (copied, docs_dir))

                # Censisci anche i percorsi originali sottomessi in projects.json (merge additivo,
                # mai sovrascrittura), cosi' restano tracciati come fonte anche se un domani la
                # copia locale viene spostata/rimossa. L'indicizzazione vera e propria resta
                # affidata al passo "update" sotto (che ri-legge projects.json).
                orig_docs = [d.strip() for d in (params.get("docs") or []) if d.strip() and os.path.exists(d.strip())]
                if orig_docs and _cerebro:
                    venv_python = os.path.join(_cerebro, ".venv", "Scripts", "python.exe") if IS_WIN \
                        else os.path.join(_cerebro, ".venv", "bin", "python")
                    register_py = os.path.join(_cerebro, "scripts", "register_project.py")
                    if os.path.exists(venv_python) and os.path.exists(register_py):
                        reg_argv = [venv_python, register_py, "add", _slug, "--docs"] + orig_docs
                        self._chunk("\n=== Censimento percorsi in projects.json ===\n")
                        reg_proc = _popen_tree(reg_argv)
                        for line in reg_proc.stdout:
                            self._chunk(line)
                        reg_proc.wait()
                        if reg_proc.returncode != 0:
                            self._chunk("\n[AVVISO] Censimento percorsi in projects.json fallito (exit %s) — la copia e' comunque avvenuta.\n" % reg_proc.returncode)
                    else:
                        self._chunk("\n[AVVISO] venv/register_project.py di CEREBRO non trovati in '%s' — percorsi non censiti in projects.json.\n" % _cerebro)
            for label, argv in build_commands(params):
                with RUN_LOCK:
                    if RUNNING["stop_requested"]:
                        break
                self._chunk("\n=== %s ===\n" % label)
                proc = _popen_tree(argv)
                with RUN_LOCK:
                    RUNNING["proc"] = proc
                for line in proc.stdout:
                    self._chunk(line)
                proc.wait()
                with RUN_LOCK:
                    RUNNING["proc"] = None
                    stopped = RUNNING["stop_requested"]
                if stopped:
                    self._chunk("\n[FERMATO] '%s' interrotto su richiesta dell'utente.\n" % label)
                    ok = False
                    break
                if proc.returncode != 0:
                    self._chunk("\n[ERRORE] '%s' exited with code %s — stopped.\n" % (label, proc.returncode))
                    ok = False
                    break
            if ok:
                self._chunk("\n" + done_msg + "\n")
        except Exception as e:
            self._chunk("\n[ERRORE] %s\n" % e)
            ok = False
        finally:
            with RUN_LOCK:
                RUNNING["proc"] = None
        self._end_stream()


def main():
    port = DEFAULT_PORT
    if "--port" in sys.argv:
        port = int(sys.argv[sys.argv.index("--port") + 1])

    httpd = None
    while httpd is None:
        try:
            httpd = ThreadingHTTPServer((HOST, port), Handler)
        except OSError:
            port += 1

    url = "http://%s:%d/" % (HOST, port)
    print("LIMET launcher: %s" % url)
    print("Ctrl+C to stop.")
    threading.Timer(0.8, lambda: webbrowser.open(url)).start()
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        httpd.server_close()


if __name__ == "__main__":
    main()
