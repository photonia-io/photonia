---
name: merged
description: Clean up after a GitHub pull request that was already merged manually on GitHub (its remote branch may or may not have been deleted) — deletes the remote branch if still present, pulls the default branch, and deletes the local feature branch. Use when the user says "merged this PR", "I merged the <description> PR", or similar — an argument naming the PR is optional.
allowed-tools:
  - Bash
  - AskUserQuestion
---

# Merged

Cleans up after a PR that the user already merged by hand on GitHub. Same end state as the `merge` skill, but skips the merge step itself (and the CI wait, since it already ran) and doesn't assume the remote branch was deleted — GitHub's "Delete branch" button is easy to forget.

## 1. Resolve the target PR

- **No argument given**: run `gh pr view --json number,title,headRefName,url,state` for the current branch.
- **Argument given**: run `gh pr list --state merged --json number,title,headRefName,url,mergedAt -L 50` (recently merged PRs) and match the argument against title/branch name using judgment, same as the `merge` skill.
  - Exactly one clear match → use it.
  - Multiple plausible matches → list them and ask via AskUserQuestion.
  - No match in merged PRs → also check `gh pr list --state open ...` and `--state closed ...` for it. If it's actually still open, say so and suggest the `merge` skill instead. If it's closed without merging, say so and stop — don't clean up branches for an abandoned PR without confirming that's intended.

## 2. Preconditions

- Confirm the PR's `state` is `MERGED`. If not, handle per the branching above rather than proceeding.
- Run `git status`. If there are uncommitted changes, stash them (`git stash push -u -m "merged skill: <branch> autostash"`) before switching branches later, rather than discarding or ignoring them. Note the stash so step 4 can restore it.

## 3. Clean up the remote branch

- Check whether it's still there: `git ls-remote --exit-code --heads origin <headRefName>`.
- If it is, delete it: `git push origin --delete <headRefName>`.
- If it isn't, that's fine — note that it was already gone, not an error.

## 4. Sync locally

- Get the default branch: `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` (fall back to `main` if that errors).
- `git checkout <default_branch>` (skip if already on it), then `git pull`.
- If `headRefName` exists as a local branch, force-delete it: `git branch -D <headRefName>`. Force is required since a squash merge won't be recognized by `-d`'s ancestry check. Skip quietly if it doesn't exist locally.
- If changes were stashed in step 2, `git stash pop` them back now. If that conflicts, say so and leave the stash in place rather than resolving it yourself.

## 5. Report

State plainly: which PR (number + title) is confirmed merged, whether its remote branch needed deleting or was already gone, that the local branch is gone, and that `<default_branch>` is up to date locally.
