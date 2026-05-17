# Intro to Microelectronics

<one-sentence description, edit me>

<!--
  This README was generated from README.md.template by
  scripts/instantiate.sh when the project was created from
  crcresearch/llm-wiki-memory-template. Placeholders substituted at
  instantiation time:
    Intro to Microelectronics   Human-readable project name.
    microelectronics-tutor-demo      Repository slug (used for the wiki path).
    chrissweet          GitHub owner / org (derived from origin URL).
    <one-sentence description, edit me>    Project description; default text below until edited.

  Edit this file freely once the project is up. The structure below is a
  suggestion, not a requirement; sections "This repository uses LLM wiki
  memory", "Quick start for collaborators", and "About the template" are
  what make this project legible to future contributors and to any AI
  coding assistant they bring along, so consider keeping them.
-->

## This repository uses LLM wiki memory

Intro to Microelectronics keeps a persistent, LLM-maintained knowledge base under `wiki/microelectronics-tutor-demo.wiki/` (a separate git repo), following the [llm-wiki pattern](https://github.com/tobi/llm-wiki). It is the project's durable memory: findings, decisions, experiment results, and intermediate insights belong in the wiki and accumulate over time. Three operations, **Query** (read it), **Ingest** (write to it), and **Lint** (health-check it), are codified in `CLAUDE.md`, in `wiki/microelectronics-tutor-demo.wiki/SCHEMA_microelectronics-tutor-demo.md`, and in the `.claude/commands/` slash commands (`/wiki-source`, `/wiki-experiment`, `/wiki-lint`).

See also [llm-wiki.md](llm-wiki.md) in this repo for the underlying pattern.

## Quick start for collaborators

New to Intro to Microelectronics? Clone the project repo, clone the wiki as a sibling sub-repo, then seed your local Claude Code memory:

```bash
git clone https://github.com/chrissweet/microelectronics-tutor-demo.git
cd microelectronics-tutor-demo
git clone https://github.com/chrissweet/microelectronics-tutor-demo.wiki.git wiki/microelectronics-tutor-demo.wiki
./wiki/agents/claude-code/setup.sh --seed-memory
```

After this, open Claude Code inside the repo. It will automatically pick up the project's slash commands (`/wiki-source` to ingest an external document, `/wiki-experiment` to file experiment results, `/wiki-lint` to health-check the wiki) along with the read/write/commit conventions in `CLAUDE.md`.

The wiki at `wiki/microelectronics-tutor-demo.wiki/` is a separate git repo with its own history and its own remote. After any wiki edit, commit in the wiki repo (not the project repo):

```bash
git -C wiki/microelectronics-tutor-demo.wiki add <files>
git -C wiki/microelectronics-tutor-demo.wiki commit -m "..."
```

Push the wiki only when you intend to publish the changes:

```bash
git -C wiki/microelectronics-tutor-demo.wiki push origin master
```

## Security considerations

Giving any AI coding assistant access to your shell and your git installation creates a real risk surface. This project's template is intentionally conservative by default — but if you're using it on sensitive code, on shared infrastructure, or in any setting where the cost of a destructive action is high, you should understand the model and lock it down further.

### The permission model in one paragraph

Claude Code (and other Claude-Code-compatible agents) runs on your machine using *your* git installation, *your* SSH keys, and *your* `gh` CLI credentials. The agent itself has no credentials — it executes commands as you. Every Bash command the agent wants to run goes through a permission check: either it matches a pre-approved pattern in `.claude/settings.json` (runs silently) or it prompts you for explicit approval (you decide). The `--dangerously-skip-permissions` flag disables this prompting entirely — that flag name is unambiguous about what it does. **Don't pass it unless you fully understand the consequences.**

### What this project pre-approves, by default

The `.claude/settings.json` shipped here pre-approves a minimal, scoped set:

| Pre-approved (no prompt) | NOT pre-approved (prompts every time) |
|---|---|
| `git status`, `git diff`, `git log` (read-only) | `git push` (any path, any remote) |
| `git -C wiki/<repo>.wiki/ add` and `commit` | `git push` to anything |
| `./scripts/kg/build-graph.sh` (if KG pipeline is present) | `gh repo delete` and other destructive `gh` operations |
| `./wiki/init-wiki.sh` and `./wiki/agents/claude-code/setup.sh` | `rm -rf`, other destructive shell operations |
| Venv Python invocations | Any command outside the allowlist |

In particular: **`git push` is never pre-approved** in the default template. The agent must ask before publishing anything to a remote. **Repository deletion** via `gh repo delete` also always prompts, and GitHub itself requires a typed confirmation on top of that. **`rm -rf` and other destructive shell operations** always prompt.

### What the real risks are (and aren't)

| Risk | Can the agent do this silently? |
|---|---|
| Modify pages in the wiki sub-repo | Yes (within scope) — that's the whole point of the wiki-as-memory pattern |
| Modify files in the main repo | No — write to non-wiki paths still gates through Claude Code's Write tool, and the user sees each write |
| Commit to the main repo | No — main-repo `git add`/`commit` are not in the default allowlist |
| Push to GitHub | No — push always prompts |
| Delete a repo on GitHub | No — `gh repo delete` not pre-approved, plus typed-confirmation by GitHub |
| Force-push / wipe history | No — push always prompts |
| `rm -rf` directories | No — prompts |
| Read files and exfiltrate via web tools | **Yes — this is the realistic remaining risk.** Reading is generally allowed; web fetch/search are typically allowed. Prompt-injection in untrusted content the agent reads is the dominant real risk, not destructive repo operations. |

The pattern this template encodes is: **the wiki sub-repo is the only place the agent has autonomous write authority. Everything beyond that requires an explicit user decision.**

### Lockdown postures

Pick the posture appropriate to your risk tolerance:

**Posture A — Default (research / development on non-sensitive repos):** ship as-is. Pre-approved wiki commits keep the agent's loop fluid; everything destructive prompts. Suitable for personal projects, demos, public repos.

**Posture B — Sensitive code or shared repos:** add a separate git identity for the agent so attribution is auditable, and use a fine-grained GitHub Personal Access Token scoped to a specific list of repos rather than your full GitHub access:

```bash
# 1. Configure a per-repo agent identity
git config user.name "Your-Name-AI-Agent"
git config user.email "ai-agent@your-domain"

# 2. Create a fine-grained PAT at https://github.com/settings/personal-access-tokens
#    with repo scope limited to this project's repo + wiki repo only
#    Store it in a credential helper, not in any tracked file
```

This narrows the blast radius. Even if something goes wrong, the agent only has authority over the specific repos the PAT covers — not your entire GitHub account.

**Posture C — Worktree isolation:** for very sensitive work, run the agent inside a separate git worktree of the repo so even local destruction in the agent's working copy can't propagate to your main working tree until you merge it:

```bash
git worktree add ../microelectronics-tutor-demo-agent
cd ../microelectronics-tutor-demo-agent
# run Claude Code here, not in the main working tree
```

**Posture D — Read-only / no-write mode:** for sessions where you want analysis but no modifications, start Claude Code with the relevant Write/Edit tools disabled, or strip them via `--disallowedTools "Write Edit"` at launch. The agent can still read, search, and answer questions about the repo without being able to modify anything.

### Things you should periodically audit

- **`.claude/settings.local.json`.** This is Claude Code's per-machine, per-user "permissions I've granted ad hoc" file. It is gitignored (per the template's `.gitignore`) so it doesn't propagate to other contributors, but it accumulates broad pre-approvals over the lifetime of a project as you click "always allow" on prompts. Review it from time to time and prune anything you didn't intend to keep.
- **What's actually in `.claude/settings.json` (the committed one).** If it drifts to include broader patterns (e.g., `Bash(git push *)`) — either through edits or via PRs — that's a meaningful weakening of the posture above.

### Things to never do

- Pass `--dangerously-skip-permissions` on a session that touches code or infrastructure you care about.
- Pre-approve `git push *` or `gh repo *` patterns in the committed `settings.json`. Push and repo administration should always prompt.
- Hand the agent a full-scope GitHub PAT when a fine-grained PAT would do.
- Run the agent as `root` or with elevated permissions when an unprivileged user would do.

### The dominant remaining risk: prompt injection in untrusted content

Even with everything above locked down, the realistic remaining risk is **prompt injection** in content the agent reads — an attacker embeds hostile instructions in a wiki source PDF, a web page the agent fetches, or any other untrusted text input, and the embedded instructions try to get the agent to exfiltrate data via a web tool, read sensitive files, or open a remote connection. This risk is not specific to the wiki-llm pattern; it applies to any LLM agent with web/file access. The mitigations are the same ones the broader Claude Code documentation describes: be cautious about ingesting unverified external content into the agent's context, and audit web-fetched content before treating it as authoritative.

The wiki-llm pattern's discipline-gates and verification-gate (see [the template repo](https://github.com/crcresearch/llm-wiki-memory-template)) provide a related but different kind of safety: they catch the agent's own *content* mistakes (projection-as-fact, missing corpus tags) — not adversarial prompt injection. The two are complementary.

## About the template

This project was instantiated from [crcresearch/llm-wiki-memory-template](https://github.com/crcresearch/llm-wiki-memory-template). Maintainers who need to pull template updates, add a new agent overlay (Cursor, OpenCode, etc.), or understand the instantiate/update scripts should read the template repo's documentation.
