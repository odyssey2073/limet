#!/usr/bin/env python3
"""LIMET related projects: link/unlink projects living in unrelated folders.

Relation model: symmetric full mesh. Each linked project gets the CEREBRO collections
(`CRB_<slug>`) of all the others in the `collections` field of CEREBRO's projects.json, so
`query_qdrant.py --project <slug>` and the `limet_search` MCP tool search them all. A marked
block (LIMET-RELATED) is written into AGENTS.md / CLAUDE.md / .github/copilot-instructions.md.

Safety: stdlib only; all-or-nothing validation before any write; registry written atomically
(tmp + os.replace) with a .bak copy and a lock file; only the `collections` field is touched
(CEREBRO's `add` drops unknown keys); other registry entries are left untouched.
"""
import argparse
import contextlib
import json
import os
import re
import sys
import time
import urllib.request

START = "<!-- LIMET-RELATED:START -->"
END = "<!-- LIMET-RELATED:END -->"
MAX_PROJECTS = 20
LOCK_TIMEOUT = 15
LOCK_STALE = 120
TARGETS = ("AGENTS.md", "CLAUDE.md", os.path.join(".github", "copilot-instructions.md"))


class RelatedError(Exception):
    pass


# --- pure helpers ------------------------------------------------------------------------------


def slug_of(path):
    base = re.split(r"[\\/]", str(path).rstrip("\\/"))[-1] or str(path)
    return re.sub(r"[^a-z0-9]+", "_", base.lower()).strip("_")


def collection_of(slug):
    return "CRB_" + slug


def norm_path(path):
    p = os.path.normpath(os.path.abspath(str(path).strip()))
    return os.path.normcase(p)


def merge_collections(existing, add, self_collection=None):
    """Additive, ordered, de-duplicated merge. Never removes anything."""
    out = list(existing or [])
    for c in add:
        if c != self_collection and c not in out:
            out.append(c)
    return out


def is_workspace_collection(registry, coll, project_root):
    """A collection that belongs to the workspace folder directly above the project."""
    if not coll.startswith("CRB_"):
        return False
    entry = registry.get(coll[4:])
    if not entry or not entry.get("root") or not project_root:
        return False
    parent = os.path.dirname(os.path.normpath(str(project_root).rstrip("\\/")))
    return norm_path(entry["root"]) == norm_path(parent)


def related_of(registry, slug):
    """Collections of `slug` that are related projects (not self, not its workspace)."""
    entry = registry.get(slug) or {}
    root = entry.get("root")
    return [c for c in entry.get("collections", [])
            if c != collection_of(slug) and not is_workspace_collection(registry, c, root)]


def render_block(registry, slug, eol="\n"):
    lines = [START, "## Related projects · Progetti correlati", ""]
    lines.append("**EN** — This project is related to the projects below. Their documentation is indexed "
                 "in the listed collections, which are searched automatically together with "
                 "`" + collection_of(slug) + "` by `query_qdrant.py --project " + slug + "` and by the "
                 "`limet_search` tool. Code graphs (Graphify) remain per project: for code questions "
                 "about a related project, work in its folder.")
    lines.append("")
    lines.append("**IT** — Questo progetto è correlato ai progetti seguenti. La loro documentazione è "
                 "indicizzata nelle collection indicate, interrogate automaticamente insieme a "
                 "`" + collection_of(slug) + "` da `query_qdrant.py --project " + slug + "` e dallo strumento "
                 "`limet_search`. I grafi del codice (Graphify) restano per progetto: per domande sul "
                 "codice di un progetto correlato lavora nella sua cartella.")
    lines.append("")
    for c in related_of(registry, slug):
        entry = registry.get(c[4:]) or {}
        root = entry.get("root")
        lines.append("- `" + c + "`" + (" — " + str(root) if root else ""))
    lines.append(END)
    return eol.join(lines)


def _eol(text):
    return "\r\n" if "\r\n" in text else "\n"


def upsert_block(text, block_fn):
    """Insert/replace the LIMET-RELATED block. `block_fn(eol)` builds it. Raises on bad markers."""
    eol = _eol(text)
    block = block_fn(eol)
    s, e = text.count(START), text.count(END)
    if s == 0 and e == 0:
        trimmed = text.rstrip()
        sep = eol * 2 if trimmed else ""
        return trimmed + sep + block + eol
    if s == 1 and e == 1 and text.index(START) < text.index(END):
        i, j = text.index(START), text.index(END) + len(END)
        return text[:i] + block + text[j:]
    raise RelatedError("marker LIMET-RELATED spaiati o duplicati")


def strip_block(text):
    """Remove the block (and the blank lines it was separated by). Returns text or None if no block."""
    s, e = text.count(START), text.count(END)
    if s == 0 and e == 0:
        return None
    if not (s == 1 and e == 1 and text.index(START) < text.index(END)):
        raise RelatedError("marker LIMET-RELATED spaiati o duplicati")
    i, j = text.index(START), text.index(END) + len(END)
    head = text[:i].rstrip()
    tail = text[j:].lstrip("\r\n")
    eol = _eol(text)
    if head and tail:
        return head + eol * 2 + tail
    return (head or tail).rstrip() + (eol if (head or tail) else "")


# --- I/O ---------------------------------------------------------------------------------------


def registry_path(cerebro_home):
    if not cerebro_home or not os.path.isdir(cerebro_home):
        raise RelatedError("CEREBRO_HOME non valido: '%s'" % cerebro_home)
    p = os.path.join(cerebro_home, "projects.json")
    if not os.path.isfile(p):
        raise RelatedError("projects.json non trovato in '%s'" % cerebro_home)
    return p


def read_registry(path):
    with open(path, "rb") as f:
        raw_bytes = f.read()
    raw = raw_bytes.decode("utf-8-sig")
    if not raw.strip():
        raise RelatedError("projects.json è vuoto: nessuna scrittura eseguita")
    try:
        data = json.loads(raw)
    except ValueError as ex:
        raise RelatedError("projects.json non è un JSON valido (%s): nessuna scrittura eseguita" % ex)
    if not isinstance(data, dict):
        raise RelatedError("projects.json non ha il formato atteso: nessuna scrittura eseguita")
    return data, raw_bytes


def _write_atomic(path, text_bytes):
    tmp = path + ".tmp-%d" % os.getpid()
    with open(tmp, "wb") as f:
        f.write(text_bytes)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def serialize_registry(data):
    return (json.dumps(data, indent=2, ensure_ascii=False) + "\n").encode("utf-8")


@contextlib.contextmanager
def registry_lock(path):
    lock = path + ".lock"
    deadline = time.time() + LOCK_TIMEOUT
    fd = None
    while fd is None:
        try:
            fd = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
        except FileExistsError:
            try:
                if time.time() - os.path.getmtime(lock) > LOCK_STALE:
                    os.remove(lock)
                    continue
            except OSError:
                pass
            if time.time() > deadline:
                raise RelatedError("projects.json è bloccato da un'altra operazione: riprova")
            time.sleep(0.2)
    try:
        yield
    finally:
        os.close(fd)
        try:
            os.remove(lock)
        except OSError:
            pass


def qdrant_has_collection(name, qdrant_url):
    try:
        with urllib.request.urlopen("%s/collections/%s" % (qdrant_url.rstrip("/"), name), timeout=5) as r:
            return 200 <= r.status < 300
    except Exception:
        return False


def qdrant_up(qdrant_url):
    try:
        with urllib.request.urlopen("%s/collections" % qdrant_url.rstrip("/"), timeout=5) as r:
            return 200 <= r.status < 300
    except Exception:
        return False


# --- operations --------------------------------------------------------------------------------


def _plan_files(registry, slugs):
    """Compute (path, original_text, new_text) for the instruction files of the given slugs."""
    plan = []
    warnings = []
    for slug in slugs:
        root = (registry.get(slug) or {}).get("root")
        if not root or not os.path.isdir(root):
            warnings.append("root di '%s' non disponibile: blocco non aggiornato" % slug)
            continue
        has_rel = bool(related_of(registry, slug))
        for rel in TARGETS:
            fp = os.path.join(root, rel)
            if not os.path.isfile(fp):
                if has_rel:
                    warnings.append("file mancante (saltato): %s" % fp)
                continue
            with open(fp, "rb") as f:
                try:
                    text = f.read().decode("utf-8")
                except UnicodeDecodeError:
                    raise RelatedError("'%s' non è UTF-8: nessuna scrittura eseguita" % fp)
            try:
                if has_rel:
                    new = upsert_block(text, lambda eol, s=slug: render_block(registry, s, eol))
                else:
                    new = strip_block(text)
                    if new is None:
                        continue
            except RelatedError as ex:
                raise RelatedError("%s in '%s': nessuna scrittura eseguita" % (ex, fp))
            if new != text:
                plan.append((fp, text, new))
    return plan, warnings


def _commit(reg_path, raw_before, new_registry, plan, log):
    """Write registry (+ .bak) then files; roll everything back on any failure."""
    bak = reg_path + ".bak"
    _write_atomic(bak, raw_before)
    done = []
    try:
        _write_atomic(reg_path, serialize_registry(new_registry))
        for fp, old, new in plan:
            _write_atomic(fp, new.encode("utf-8"))
            done.append((fp, old))
    except Exception as ex:
        for fp, old in done:
            try:
                _write_atomic(fp, old.encode("utf-8"))
            except Exception:
                log("[AVVISO] ripristino fallito per %s" % fp)
        try:
            _write_atomic(reg_path, raw_before)
        except Exception:
            log("[AVVISO] ripristino registro fallito: usa %s" % bak)
        raise RelatedError("scrittura fallita (%s): modifiche annullate" % ex)


def _resolve(paths):
    if not isinstance(paths, (list, tuple)) or not all(isinstance(p, str) for p in paths):
        raise RelatedError("elenco percorsi non valido")
    paths = [p.strip() for p in paths if p and p.strip()]
    if len(paths) > MAX_PROJECTS:
        raise RelatedError("massimo %d progetti" % MAX_PROJECTS)
    return paths


def _validate_projects(paths, registry, log, allow_missing_dir=False):
    """Returns ordered list of slugs. Raises RelatedError listing every problem found."""
    errors, slugs, seen_paths = [], [], set()
    for p in paths:
        if not os.path.isdir(p) and not allow_missing_dir:
            errors.append("cartella inesistente: %s" % p)
            continue
        n = norm_path(p)
        if n in seen_paths:
            errors.append("percorso duplicato: %s" % p)
            continue
        seen_paths.add(n)
        slug = slug_of(p)
        if not slug:
            errors.append("impossibile ricavare lo slug da: %s" % p)
            continue
        if slug in slugs:
            errors.append("slug '%s' duplicato (stesso nome di cartella finale): rinomina una delle cartelle" % slug)
            continue
        entry = registry.get(slug)
        if not entry:
            errors.append("'%s' non è registrato in CEREBRO: usa prima Crea su %s" % (slug, p))
            continue
        root = entry.get("root")
        if not root:
            errors.append("'%s' non ha root registrato in CEREBRO: ripeti Crea/Re-index" % slug)
        elif norm_path(root) != n:
            errors.append("slug '%s' già registrato per un'altra cartella (%s), non per %s" % (slug, root, p))
            continue
        slugs.append(slug)
    if errors:
        raise RelatedError("validazione fallita:\n  - " + "\n  - ".join(errors))
    return slugs


def link(cerebro_home, paths, qdrant_url="http://localhost:6333", log=print):
    paths = _resolve(paths)
    if len(paths) < 2:
        raise RelatedError("servono almeno 2 progetti")
    reg_path = registry_path(cerebro_home)
    with registry_lock(reg_path):
        registry, raw = read_registry(reg_path)
        slugs = _validate_projects(paths, registry, log)
        if not qdrant_up(qdrant_url):
            raise RelatedError("Qdrant non raggiungibile su %s" % qdrant_url)
        missing = [collection_of(s) for s in slugs if not qdrant_has_collection(collection_of(s), qdrant_url)]
        if missing:
            raise RelatedError("collection assenti su Qdrant: %s (usa Crea/Re-index)" % ", ".join(missing))
        new = json.loads(json.dumps(registry))
        for s in slugs:
            others = [collection_of(o) for o in slugs if o != s]
            entry = new[s]
            entry["collections"] = merge_collections(entry.get("collections"), others, collection_of(s))
        plan, warnings = _plan_files(new, slugs)
        _commit(reg_path, raw, new, plan, log)
    for w in warnings:
        log("[AVVISO] " + w)
    for s in slugs:
        log("%s -> correlati: %s" % (s, ", ".join(related_of(new, s)) or "-"))
    log("Collegati %d progetti. Nessun Re-index necessario." % len(slugs))
    return slugs


def unlink(cerebro_home, paths, log=print):
    """>=2 paths: remove the mutual links. 1 path: detach it from everything (used before remove)."""
    paths = _resolve(paths)
    if not paths:
        raise RelatedError("nessun progetto indicato")
    reg_path = registry_path(cerebro_home)
    with registry_lock(reg_path):
        registry, raw = read_registry(reg_path)
        slugs = _validate_projects(paths, registry, log, allow_missing_dir=True)
        new = json.loads(json.dumps(registry))
        affected = set()

        def drop(frm, coll):
            e = new.get(frm)
            if e and coll in e.get("collections", []):
                e["collections"] = [c for c in e["collections"] if c != coll]
                if not e["collections"]:
                    del e["collections"]
                affected.add(frm)

        if len(slugs) == 1:
            s = slugs[0]
            for c in related_of(registry, s):
                drop(s, c)
            for other in list(new):
                if other != s and collection_of(s) in new[other].get("collections", []):
                    if not is_workspace_collection(registry, collection_of(s), (registry[other] or {}).get("root")):
                        drop(other, collection_of(s))
            affected.add(s)
        else:
            for a in slugs:
                for b in slugs:
                    if a != b:
                        drop(a, collection_of(b))
        plan, warnings = _plan_files(new, sorted(affected))
        _commit(reg_path, raw, new, plan, log)
    for w in warnings:
        log("[AVVISO] " + w)
    log("Collegamenti rimossi per: %s" % ", ".join(sorted(affected)) if affected else "Nessun collegamento da rimuovere.")
    return sorted(affected)


def add_extra(cerebro_home, slug, collection):
    """Idempotent additive merge of one extra collection (used by limet-index init)."""
    reg_path = registry_path(cerebro_home)
    with registry_lock(reg_path):
        registry, raw = read_registry(reg_path)
        if slug not in registry:
            raise RelatedError("progetto '%s' non registrato" % slug)
        new = json.loads(json.dumps(registry))
        new[slug]["collections"] = merge_collections(new[slug].get("collections"), [collection], collection_of(slug))
        if new != registry:
            _commit(reg_path, raw, new, [], print)


def check(cerebro_home, paths):
    """Non-destructive validation. Returns list of problems (empty = OK)."""
    paths = _resolve(paths)
    reg_path = registry_path(cerebro_home)
    registry, _ = read_registry(reg_path)
    try:
        if len(paths) < 2:
            raise RelatedError("servono almeno 2 progetti")
        _validate_projects(paths, registry, print)
    except RelatedError as ex:
        return [str(ex)]
    return []


def main(argv=None):
    ap = argparse.ArgumentParser(description="LIMET related projects")
    ap.add_argument("command", choices=["link", "unlink", "check", "add-extra"])
    ap.add_argument("--cerebro-home", required=True)
    ap.add_argument("--path", action="append", default=[])
    ap.add_argument("--slug")
    ap.add_argument("--collection")
    ap.add_argument("--qdrant-url", default=os.getenv("QDRANT_URL", "http://localhost:6333"))
    a = ap.parse_args(argv)
    try:
        if a.command == "link":
            link(a.cerebro_home, a.path, a.qdrant_url)
        elif a.command == "unlink":
            unlink(a.cerebro_home, a.path)
        elif a.command == "add-extra":
            if not a.slug or not a.collection:
                raise RelatedError("--slug e --collection sono obbligatori")
            add_extra(a.cerebro_home, a.slug, a.collection)
        else:
            problems = check(a.cerebro_home, a.path)
            for p in problems:
                print(p)
            return 1 if problems else 0
    except RelatedError as ex:
        print("[ERRORE] %s" % ex)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
