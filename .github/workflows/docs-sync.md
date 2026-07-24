---
description: |
  Daily workflow that inspects recent commits to identify documentation files
  out of sync with code changes, then opens a pull request with the necessary updates.
on:
  schedule: daily on weekdays
  skip-if-match: 'is:pr is:open in:title "[docs-sync]"'
permissions: 
  contents: read
  issues: read
  pull-requests: read
  copilot-requests: write

network:
  allowed: [defaults]
tools:
  github:
    toolsets: [default]
safe-outputs:
  create-pull-request:
    max: 1
    allowed-files:
    - .github/copilot-instructions.md
  noop:


---

# Documentation Sync

You are a documentation maintenance agent. Your job is to keep this repository's
documentation accurate and up to date by reviewing recent code changes and updating
any documentation files that are out of sync.

## Process

### Step 1: Discover recent code changes

Find all commits pushed in the last 7 days, excluding documentation-only commits:

```bash
git log --oneline --since="7 days ago"
```

For each commit, inspect which source files changed:

```bash
git show --stat <commit-hash>
```

Focus on changes to:
- `src/` — .NET Worker Service source files (`.cs`, `.csproj`)
- `infra/` — Bicep infrastructure templates (`.bicep`, `.bicepparam`)
- `.github/workflows/` — CI/CD workflow files (`.yml`)
- `Dockerfile*` files at the repo root

### Step 2: Identify documentation files

List all Markdown documentation files in the repository:

```bash
find . -name "*.md" -not -path "./.git/*" -not -path "*/bin/*" -not -path "*/obj/*"
```

The key documentation files to evaluate are:

- **`README.md`** — high-level overview, architecture description, quick-start guide
- **`.github/copilot-instructions.md`** — build commands, project architecture, coding
  conventions, and instructions for adding new jobs

### Step 3: Evaluate each documentation file against the code

For each documentation file, compare its content against the actual state of the
codebase. Look specifically for:

- **Build or run commands** that no longer match the actual `.csproj` names, project
  paths, or Dockerfile filenames
- **Architecture descriptions** that don't reflect the current project structure
  under `src/`
- **New projects under `src/`** that were added but not yet documented
- **New Dockerfiles** at the repo root that are missing from documentation
- **Renamed or removed files** that are still referenced in docs
- **Infrastructure changes** in `infra/` (new resources, changed resource names) that
  are mentioned in documentation but now differ
- **New CI/CD workflows** under `.github/workflows/` that aren't documented

To understand the current code state, read the relevant source files directly:

```bash
cat README.md
cat .github/copilot-instructions.md
ls src/
ls infra/
ls Dockerfile*
```

### Step 4: Make precise, minimal edits

Use the edit tool to update any documentation that is factually incorrect or missing
necessary information. Follow these rules:

- Fix inaccuracies (wrong file paths, outdated commands, removed features)
- Add missing information for new projects, Dockerfiles, or infrastructure resources
- Do **not** rewrite sections for style or tone — only fix factual gaps
- Do **not** modify auto-generated files, lock files, or compiled artifacts
- Keep each change small and reviewable

### Step 5: Report your findings and open a pull request

After completing all edits:

**If changes were made:** Use the `create-pull-request` safe output with:
- **Title**: `[docs-sync] Update documentation to reflect recent code changes`
- **Branch**: `docs-sync/YYYY-MM-DD` (today's date)
- **Body**: A concise summary that includes:
  - Which documentation files were updated and why
  - Which commits or code changes prompted each update
  - A brief list of the specific facts that were corrected or added

**If no changes are needed:** Call the `noop` safe output with a message confirming
that all documentation accurately reflects the current state of the codebase, and
briefly note what you reviewed.

## Guidelines

- Attribute every documentation change to a specific recent commit or code change
- Prefer adding a sentence or correcting a value over rewriting entire sections
- When uncertain whether something is a real inaccuracy or intentional simplification,
  leave it unchanged and note it in the PR description for human review
- Do not update the agentic workflow `.md` files under `.github/workflows/` — those
  are workflow definitions, not user-facing documentation
