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
import webbrowser
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import re
import urllib.error
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
HOST = "127.0.0.1"
DEFAULT_PORT = 8799
IS_WIN = os.name == "nt"

ACTIONS = ("create", "update", "status", "remove", "instructions", "adddocs")

QDRANT_URL = os.getenv("QDRANT_URL", "http://localhost:6333")
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://localhost:11434")


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


def _docs_dir(slug, path, cerebro):
    """The project's CEREBRO docs folder (from the registry), fallback <path>/docs."""
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
    return os.path.join(path, "docs")


def script_path(name):
    return os.path.join(HERE, name + (".ps1" if IS_WIN else ".sh"))


def read_html():
    with open(os.path.join(HERE, "launcher.html"), "r", encoding="utf-8") as f:
        return f.read()


# --- command building --------------------------------------------------------------------------


def _index_cmd(sub, path, cerebro_home, lang="en", workspace=False):
    """Build the limet-index command (init/update/status/remove) for this platform."""
    if IS_WIN:
        cmd = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
               script_path("limet-index"), sub, "-ProjectPath", path]
        if sub in ("init", "instructions"):
            cmd += ["-Lang", lang]
            if sub == "init" and workspace:
                cmd += ["-Workspace"]
        if cerebro_home:
            cmd += ["-CerebroHome", cerebro_home]
        return cmd
    cmd = ["bash", script_path("limet-index"), sub, "--project-path", path]
    if sub in ("init", "instructions"):
        cmd += ["--lang", lang]
        if sub == "init" and workspace:
            cmd += ["--workspace"]
    if cerebro_home:
        cmd += ["--cerebro-home", cerebro_home]
    return cmd


def build_commands(params):
    """Return the ordered list of (label, argv) for the requested action."""
    action = params.get("action", "create")
    path = params["path"]
    lang = params.get("lang", "en")
    workspace = bool(params.get("workspace"))
    context = bool(params.get("context"))
    cerebro_home = params.get("cerebro_home") or ""

    if action == "instructions":
        return [("Generate documentation", _index_cmd("instructions", path, cerebro_home, lang))]
    if action == "adddocs":
        return [("Re-index", _index_cmd("update", path, cerebro_home))]
    if action == "update":
        return [("LIMET re-index", _index_cmd("update", path, cerebro_home))]
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
        self.send_response(200)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Transfer-Encoding", "chunked")
        self.send_header("Cache-Control", "no-cache")
        self.end_headers()

    def _chunk(self, data):
        if not data:
            return
        if isinstance(data, str):
            data = data.encode("utf-8")
        self.wfile.write(("%x\r\n" % len(data)).encode("ascii"))
        self.wfile.write(data)
        self.wfile.write(b"\r\n")
        self.wfile.flush()

    def _end_stream(self):
        try:
            self.wfile.write(b"0\r\n\r\n")
            self.wfile.flush()
        except (BrokenPipeError, ConnectionResetError):
            pass

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
            cerebro = q.get("cerebro", [os.environ.get("CEREBRO_HOME", "")])[0].strip()
            if not path:
                self._json({"error": "path required"}, 400)
                return
            slug = slugify(os.path.basename(path.rstrip("\\/")) or path)
            collection = "CRB_" + slug
            registered = False
            if cerebro:
                reg_file = os.path.join(cerebro, "projects.json")
                if os.path.exists(reg_file):
                    try:
                        with open(reg_file, encoding="utf-8") as f:
                            registered = slug in json.load(f)
                    except Exception:
                        registered = False
            qdrant_up = _get_ok(f"{QDRANT_URL}/collections")
            ollama_up = _get_ok(OLLAMA_URL)
            docs_dir = _docs_dir(slug, path, cerebro)
            existing_docs = []
            if os.path.isdir(docs_dir):
                for root, _dirs, files in os.walk(docs_dir):
                    for fn in files:
                        if fn.lower().endswith((".md", ".txt", ".pdf", ".epub", ".docx", ".xlsx", ".pptx", ".html", ".htm")):
                            existing_docs.append(os.path.relpath(os.path.join(root, fn), docs_dir))
            existing_docs = sorted(existing_docs)
            self._json({
                "slug": slug,
                "collection": collection,
                "registered": registered,
                "qdrant_up": qdrant_up,
                "ollama_up": ollama_up,
                "collection_created": _collection_exists(collection) if qdrant_up else False,
                "docs_dir": docs_dir,
                "docs_count": len(existing_docs),
                "existing_docs": existing_docs[:20],
            })
        else:
            self.send_response(404)
            self.end_headers()

    def do_POST(self):
        parsed = urlparse(self.path)
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

        path = (params.get("path") or "").strip()
        action = params.get("action") or "create"
        if not path:
            self._json({"error": "project path is required"}, 400)
            return
        if action not in ACTIONS:
            self._json({"error": "unknown action: %s" % action}, 400)
            return

        done_msg = {
            "create": "Fatto. Il progetto è pronto.",
            "update": "Fatto. Indici aggiornati.",
            "status": "Fatto.",
            "remove": "Fatto. Progetto rimosso dal registry (la collection Qdrant resta).",
            "instructions": "Fatto. Documentazione generata (CLAUDE.md + copilot-instructions.md).",
            "adddocs": "Fatto. Documenti aggiunti e indicizzati.",
        }[action]

        self._start_stream()
        ok = True
        try:
            if action == "adddocs":
                _slug = slugify(os.path.basename(path.rstrip("\\/")) or path)
                _cerebro = (params.get("cerebro_home") or "").strip()
                docs_dir = _docs_dir(_slug, path, _cerebro)
                os.makedirs(docs_dir, exist_ok=True)
                copied = 0
                for d in (params.get("docs") or []):
                    d = d.strip()
                    if not d or not os.path.exists(d):
                        continue
                    if os.path.isdir(d):
                        for root, _dirs, files in os.walk(d):
                            for fn in files:
                                shutil.copy2(os.path.join(root, fn), os.path.join(docs_dir, fn))
                                copied += 1
                    else:
                        shutil.copy2(d, os.path.join(docs_dir, os.path.basename(d)))
                        copied += 1
                self._chunk("\nCopiati %d file in %s\n" % (copied, docs_dir))
            for label, argv in build_commands(params):
                self._chunk("\n=== %s ===\n" % label)
                proc = subprocess.Popen(
                    argv,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    encoding="utf-8",
                    errors="replace",
                    bufsize=1,
                )
                for line in proc.stdout:
                    self._chunk(line)
                proc.wait()
                if proc.returncode != 0:
                    self._chunk("\n[ERRORE] '%s' exited with code %s — stopped.\n" % (label, proc.returncode))
                    ok = False
                    break
            if ok:
                self._chunk("\n" + done_msg + "\n")
        except Exception as e:
            self._chunk("\n[ERRORE] %s\n" % e)
            ok = False
        self._end_stream()


def main():
    port = DEFAULT_PORT
    if "--port" in sys.argv:
        port = int(sys.argv[sys.argv.index("--port") + 1])

    httpd = None
    while httpd is None:
        try:
            httpd = HTTPServer((HOST, port), Handler)
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
