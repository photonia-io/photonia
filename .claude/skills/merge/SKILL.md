---
name: merge
description: Squash-merge a GitHub pull request via gh, waiting for CI to go green first, then delete its remote branch, pull the default branch locally, and delete the local feature branch. Use when the user says "merge this PR", "merge the <description> PR", or similar — an argument naming the PR is optional.
allowed-tools:
  - Bash
  - AskUserQuestion
---

# Merge

Squash-merges an open GitHub PR with `gh`, waiting for CI to finish green, then syncs the local repo to match. Works from any branch in the repo, and accepts a free-text argument naming the PR (e.g. "the commenting system pr") when the current branch isn't the PR's branch.

## 1. Resolve the target PR

- **No argument given**: run `gh pr view --json number,title,headRefName,url,state` for the current branch. If there's no PR for the current branch, say so and stop — don't guess.
- **Argument given**: run `gh pr list --state open --json number,title,headRefName,url -L 50` and match the argument against the title and branch name using judgment (semantic match, not literal substring — "the commenting system pr" should match a PR titled "Add comments to photos" or a branch like `add-comments`).
  - Exactly one clear match → use it.
  - Multiple plausible matches → list them (number + title) and ask the user with AskUserQuestion which one.
  - No match → say so and stop; don't fall back to the current branch's PR without confirming that's what was meant.

## 2. Preconditions

- The PR's `state` must be `OPEN`. If it's already `MERGED`, tell the user and suggest the `merged` skill instead. If `CLOSED`, say so and stop.
- Check mergeability: `gh pr view <number> --json mergeable,mergeStateStatus`. If `mergeable` isn't `MERGEABLE` (conflicts, etc.), report exactly what's blocking it and stop — don't force anything.
- Run `git status`. If there are uncommitted changes, stash them (`git stash push -u -m "merge skill: <branch> autostash"`) before switching branches later, rather than discarding or ignoring them. Note the stash so step 5 can restore it.

## 3. Wait for CI

- `gh pr checks <number> --watch --fail-fast`. This polls until every check finishes (or exits early on the first failure with `--fail-fast`).
- If it reports no checks are configured for the branch, note that and proceed — nothing to wait for.
- If it exits clean, all checks passed — proceed.
- If any check failed, stop. Report which check(s) failed (`gh pr checks <number>` lists names and links) and do not merge — don't override a red CI run without the user explicitly asking to.
- While watching, it's fine to let `gh` block for a while; this is expected to take as long as CI takes.

## 4. Merge

- `gh pr merge <number> --squash --delete-branch`. This squash-merges and deletes the remote branch in one call. If it fails (e.g. required review missing, branch protection), report the error verbatim and stop — don't retry with `--admin` or similar without the user asking.

## 5. Sync locally

- Get the default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` (fall back to `main` if that errors).
- `git checkout <default_branch>` (skip if already on it), then `git pull`.
- If the PR's `headRefName` exists as a local branch, force-delete it: `git branch -D <headRefName>`. Force is required — a squash merge produces a new commit, so `-d` won't recognize the branch as merged. Skip quietly if it doesn't exist locally.
- If changes were stashed in step 2, `git stash pop` them back now. If that conflicts, say so and leave the stash in place rather than resolving it yourself.

## 6. Report

State plainly: which PR (number + title) was merged, that CI was green (or that there were no checks to wait for), that its remote and local branches are gone, and that `<default_branch>` is up to date locally. Mention anything that was skipped (no local branch existed, nothing to stash, etc.).
