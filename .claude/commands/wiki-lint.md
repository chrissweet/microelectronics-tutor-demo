---
description: Health-check the wiki for orphans, dead links, stale claims, missing frontmatter.
---

You are running a health check on the wiki at `wiki/microelectronics-tutor-demo.wiki/`. Defer to `SCHEMA_microelectronics-tutor-demo.md` for the precise conventions.

Full procedure: see `.claude/skills/wiki-lint.md`. Summary:

1. Read `index_microelectronics-tutor-demo.md` to get the canonical list of pages.
2. List all `.md` files in the wiki directory.
3. Scan systematically for each check below and collect findings:
   - **Orphan pages** (no inbound links from other pages or index)
   - **Dead links** (`[Display](Page)` or `[[Page]]` pointing to non-existent files)
   - **Stale claims** (superseded by newer pages or current code/results)
   - **Missing frontmatter** (no block at top, or missing `type:` / `up:`)
   - **`type: untyped`** pages whose proper type is now obvious
   - **Missing concept pages** (concepts mentioned in multiple bodies without their own page)
   - **Missing cross-references** in either direction (if A → B, B should → A)
   - **Index gaps** (pages in wiki but not listed in `index_…md`)
   - **Naming convention** deviations (should be `Title-Case-Hyphenated.md`)
   - **Special-file integrity** (`Home_…`, `index_…`, `log_…`, `SCHEMA_…`, `Home.md` redirect)
4. Report findings to the user grouped by check type, with one or two example pages per finding.
5. Ask which findings to fix in this pass. Lint is incremental.
6. For accepted fixes, apply them with cross-reference repair in both directions, update `index_microelectronics-tutor-demo.md` as needed, and append a `## [YYYY-MM-DD] lint | Subject` entry to `log_microelectronics-tutor-demo.md`.
7. Optionally rebuild the knowledge graph: `./scripts/kg/build-graph.sh`.
8. **Finish the cycle.** Stage and commit in the wiki's own git repo, without asking:
    ```
    git -C wiki/microelectronics-tutor-demo.wiki add <files-by-name>
    git -C wiki/microelectronics-tutor-demo.wiki commit -m "lint: <summary>"
    ```
    Local commits are reversible. Push only if the user requests.

Honest reporting: do not paper over contradictions. If two pages disagree and current code/results decide between them, update the loser and link to the winner.
