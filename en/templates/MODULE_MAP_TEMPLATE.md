# Module/project map — [Workspace name]

> Reference document for a **workspace** made of several correlated projects/repositories (or a
> single repository split into several modules, each treated as its own "project" for LIMET
> purposes). Keep it up to date: it is the first thing to read before planning a change that
> touches more than one project/module.

## Project/module list

| Project/module | Local path | Role/responsibility | Own repository? |
| ---------------- | ---------- | ---------------------- | ------------------- |
| [project-name-1] | [path]     | [what it does]          | [yes/no — if "no", it is a module of the same repo as the workspace] |
| [project-name-2] | [path]     | [what it does]          | [...]                 |

## Relationships and dependencies between projects/modules

> Who calls whom, who produces a contract (API/schema/event) and who consumes it. Needed to
> establish the implementation order when a change spans more than one project.

| Producer | Consumer | Contract/interface | Communication type |
| -------- | -------- | --------------------- | ---------------------- |
| [...]    | [...]    | [...]                 | [e.g. internal REST/API, async event, shared library] |

## Recommended build/deploy order (if relevant)

[If there is a mandatory order to compile/deploy changes — e.g. "the contract producer must be
updated and released before the consumers" — describe it here.]

## Shared conventions across the workspace's projects

[Any naming conventions, contract versioning, shared terminology — see also each project's
`GLOSSARY_TEMPLATE.md`, or a workspace-level shared glossary if created.]

## Notes

- Every project/module listed here has (or should have) its own local LIMET installation
  (`AGENTS.md` + `CLAUDE.md` + `limet/` folder) — see `FRAMEWORK_MANUAL.md` §9 and Appendix C.
- This document lives in the workspace folder (`limet-workspace/MODULE_MAP.md`), not inside a
  single project.

## Change history for this map

- **[YYYY-MM-DD]**: [what changed — new project added, contract changed, etc.]
