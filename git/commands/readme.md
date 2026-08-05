# Git Commands: Complete Step-by-Step Guide

## Table of content

1.  [Initial Setup](#1-initial-setup)
2.  [Starting a Repository](#2-starting-a-repository)
3.  [Checking Status & Basic Workflow](#3-checking-status--basic-workflow)
4.  [Staging & Committing](#4-staging--committing)
5.  [Viewing History](#5-viewing-history)
6.  [Branching](#6-branching)
7.  [Merging](#7-merging)
8.  [Handling Merge Conflicts](#8-handling-merge-conflicts)
9.  [Rebasing](#9-rebasing)
10. [Cherry-Picking](#10-cherry-picking)
11. [Working with Remotes](#11-working-with-remotes)
12. [Undoing Changes](#12-undoing-changes)
13. [Stashing (Save Work Temporarily)](#13-stashing-save-work-temporarily)
14. [Tags (Marking Releases)](#14-tags-marking-releases)
15. [Inspecting & Comparing](#15-inspecting--comparing)
16. [Cleaning Up](#16-cleaning-up)
17. [Ignoring Files](#17-ignoring-files)
18. [Typical Everyday Workflow (Putting It Together)](#18-typical-everyday-workflow-putting-it-together)
19. [Reflog (Recovering Lost Work)](#19-reflog-recovering-lost-work)
20. [Submodules](#20-submodules)
21. [Worktrees](#21-worktrees)
22. [Aliases & Global Ignore](#22-aliases--global-ignore)
23. [Renaming, Removing & Archiving](#23-renaming-removing--archiving)

## Quick Reference Table

| Task | Command |
|---|---|
| Vs code in Github | `.` |
| Initialize repo | `git init` |
| Clone repo | `git clone <url>` |
| Check status | `git status` |
| Stage file | `git add <file>` |
| Commit | `git commit -m "message"` |
| View history | `git log --oneline` |
| Create branch | `git checkout -b <name>` |
| Switch branch | `git switch <name>` |
| Merge branch | `git merge <name>` |
| Cherry-pick a commit | `git cherry-pick <hash>` |
| Pull changes | `git pull` |
| Push changes | `git push` |
| Undo last commit (keep changes) | `git reset --soft HEAD~1` |
| Discard file changes | `git restore <file>` |
| Stash changes | `git stash` |
| Apply stash | `git stash pop` |
| View reflog | `git reflog` |
| Remove a file | `git rm <file>` |
| Rename/move a file | `git mv <old> <new>` |
| Add submodule | `git submodule add <url>` |
| Add worktree | `git worktree add <path> <branch>` |
| Create alias | `git config --global alias.<name> <command>` |
| List remotes URLs | `git remote -v` |


## 1. Initial Setup

```bash
# Install check
git --version

# Set your identity (required before first commit)
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Set default branch name to 'main'
git config --global init.defaultBranch main

# Set default editor (optional)
git config --global core.editor "code --wait"

# View all config settings
git config --list

# Pull Up the Local System Manual for a Specific Subcommand
git help config
```

## 2. Starting a Repository

```bash
# Option A: Create a new repo in current folder
git init

# Add Folder to an existing remote repo
git remote add orgin https://github.com/username/repo

#  Option B: Clone a Repo from Github
git clone https://github.com/username/repo.git

# Move to the clone Repo
cd /repo
# Add Readme.md file
git add README.md
```

## 3. Checking Status & Basic Workflow

```bash
# See current state: staged, unstaged, untracked files
git status

# See what changed (line by line)
git diff

# See staged changes only
git diff --staged
```

## 4. Staging & Committing

```bash
# Stage a specific file
git add filename.txt

# Stage multiple files
git add file1.txt file2.txt

# Stage everything (new, modified, deleted)
git add .

# Stage interactively (choose hunks)
git add -p

# Commit staged changes
git commit -m "Your commit message"

# Stage all tracked changes AND commit in one step
git commit -am "Your commit message"

# Amend the last commit (edit message or add files)
git commit --amend -m "Updated message"

# Amend without changing the commit message
git commit --amend --no-edit

# Skip pre-commit/commit-msg hooks
git commit -m "message" --no-verify

# Create a fixup commit targeting an earlier commit (for later autosquash)
git commit --fixup <commit-hash>
```

## 5. Viewing History

```bash
# Full commit log
git log

# Compact one-line log
git log --oneline

# Log with graph of branches
git log --oneline --graph --all

# Show a specific commit's changes
git show <commit-hash>

# See who changed each line of a file
git blame filename.txt

# Blame a specific range of lines
git blame -L 10,25 filename.txt

# Log with diffs for each commit
git log -p

# Log with a summary of files changed and line counts
git log --stat

# Filter log by author
git log --author="Jane Doe"

# Filter log by date range
git log --since="2 weeks ago" --until="yesterday"

# Filter log by commit message content
git log --grep="fix"

# Filter log to commits touching a specific file
git log -- filename.txt

# Follow a file's history through renames
git log --follow filename.txt

# Show commit counts per author
git shortlog -sn

# Show the nearest tag reachable from a commit (useful for versioning)
git describe --tags
```

## 6. Branching

```bash
# List all local branches
git branch

# List all branches (local + remote)
git branch -a

# Create a new branch
git branch feature-name

# Switch to a branch
git checkout feature-name
# or (modern syntax)
git switch feature-name

# Create AND switch to a new branch in one step
git checkout -b feature-name
# or
git switch -c feature-name

# Rename current branch
git branch -m new-branch-name

# Delete a local branch (safe, checks if merged)
git branch -d feature-name

# Force delete a local branch (unmerged changes lost)
git branch -D feature-name

# List branches already merged into current branch (safe to delete)
git branch --merged

# List branches NOT yet merged into current branch
git branch --no-merged

# List local branches with their upstream tracking status
git branch -vv

# Delete a remote branch
git push origin --delete feature-name
```

## 7. Merging

```bash
# Switch to the branch you want to merge INTO (e.g. main)
git checkout main

# Merge another branch into current branch
git merge feature-name

# Merge with a merge commit even if fast-forward is possible
git merge --no-ff feature-name

# Abort a merge if conflicts get messy
git merge --abort
```

## 8. Handling Merge Conflicts

```bash
# 1. Git will mark conflicted files after a failed merge
git status

# 2. Open each conflicted file and resolve the <<<<<<< ======= >>>>>>> markers manually

# 3. Mark the conflict as resolved
git add filename.txt

# 4. Complete the merge
git commit
```

## 9. Rebasing

```bash
# Rebase current branch onto main
git checkout feature-name
git rebase main

# Continue after resolving a conflict during rebase
git rebase --continue

# Skip a problematic commit during rebase
git rebase --skip

# Abort the rebase entirely
git rebase --abort

# Interactive rebase (squash, reorder, edit last 3 commits)
git rebase -i HEAD~3
```

## 10. Cherry-Picking

```bash
# Apply a single commit from another branch onto your current branch
git cherry-pick <commit-hash>

# Cherry-pick multiple commits
git cherry-pick <commit-hash-1> <commit-hash-2>

# Cherry-pick a range of commits (exclusive of the first, inclusive of the last)
git cherry-pick <start-commit-hash>..<end-commit-hash>

# Cherry-pick without auto-committing (lets you review/edit before committing)
git cherry-pick -n <commit-hash>

# Continue after resolving a conflict during cherry-pick
git cherry-pick --continue

# Skip the current commit if it's already applied/empty
git cherry-pick --skip

# Abort the cherry-pick and return to the pre-cherry-pick state
git cherry-pick --abort

# Cherry-pick a commit but edit the commit message before committing
git cherry-pick --edit <commit-hash>
```

## 11. Working with Remotes

```bash
# View configured remotes
git remote -v

# Add a remote
git remote add origin https://github.com/username/repo.git

# Change a remote's URL
git remote set-url origin https://github.com/username/new-repo.git

# Remove a remote
git remote remove origin

# Fetch changes without merging
git fetch origin

# Pull changes (fetch + merge)
git pull origin main

# Pull with rebase instead of merge
git pull --rebase origin main

# Push changes
git push origin main

# Push a new branch and set upstream tracking
git push -u origin feature-name

# Push all branches
git push --all origin

# Force push (use with caution — overwrites remote history)
git push --force origin main

# Safer force push (fails if remote has new commits you don't have)
git push --force-with-lease origin main

# Show detailed info about a remote (tracked branches, push/pull URLs)
git remote show origin

# Fetch from all remotes and remove references to deleted remote branches
git fetch --all --prune

# Pull only if it can fast-forward (fails instead of creating a merge commit)
git pull --ff-only
```

## 12. Undoing Changes

```bash
# Discard changes in a file (before staging)
git checkout -- filename.txt
# or (modern syntax)
git restore filename.txt

# Unstage a file (keep the changes)
git restore --staged filename.txt
# or (older syntax)
git reset filename.txt

# Drop Specific File Allocations out of Staging Directories
git reset filename.txt

# Undo the last commit but keep changes staged
git reset --soft HEAD~1

# Undo the last commit and unstage changes (keep in working directory)
git reset --mixed HEAD~1

# Undo the last commit and DISCARD all changes (destructive)
git reset --hard HEAD~1

# Revert a commit by creating a new "undo" commit (safe for shared history)
git revert <commit-hash>


```

## 13. Stashing (Save Work Temporarily)

```bash
# Stash current changes
git stash

# Stash with a message
git stash save "work in progress on login form"

# List all stashes
git stash list

# Reapply the most recent stash and remove it from the list
git stash pop

# Reapply a stash without removing it
git stash apply

# Reapply a specific stash
git stash apply stash@{2}

# Delete a specific stash
git stash drop stash@{2}

# Delete all stashes
git stash clear
```

## 14. Tags (Marking Releases)

```bash
# Create a lightweight tag
git tag v1.0.0

# Create an annotated tag (recommended, includes message)
git tag -a v1.0.0 -m "Release version 1.0.0"

# List all tags
git tag

# Push a single tag to remote
git push origin v1.0.0

# Push all tags to remote
git push origin --tags

# Delete a local tag
git tag -d v1.0.0

# Delete a remote tag
git push origin --delete v1.0.0
```

## 15. Inspecting & Comparing

```bash
# Compare two branches
git diff main..feature-name

# Compare two commits
git diff <commit1> <commit2>

# See which branches contain a commit
git branch --contains <commit-hash>

# Find which commit introduced a bug (binary search)
git bisect start
git bisect bad                # current commit is broken
git bisect good <commit-hash> # known good commit
# Git checks out a midpoint commit — test it, then mark:
git bisect good   # or
git bisect bad
# Repeat until Git identifies the culprit commit
git bisect reset  # end the session
```

## 16. Cleaning Up

```bash
# Preview what untracked files would be removed
git clean -n

# Remove untracked files
git clean -f

# Remove untracked files AND directories
git clean -fd

# Remove ignored files too
git clean -fdx
```

## 17. Ignoring Files

```bash
# Create/edit .gitignore, then add patterns, e.g.:
# node_modules/
# *.log
# .env

# Stop tracking a file that's already committed (after adding to .gitignore)
git rm --cached filename.txt
git commit -m "Stop tracking filename.txt"
```

## 18. Typical Everyday Workflow (Putting It Together)

```bash
# 1. Get latest changes
git checkout main
git pull origin main

# 2. Create a feature branch
git checkout -b feature/new-login

# 3. Make changes, then check status
git status

# 4. Stage and commit
git add .
git commit -m "Add new login form"

# 5. Push branch to remote
git push -u origin feature/new-login

# 6. Open a Pull Request on GitHub/GitLab
# Via web UI: push output prints a PR-creation link, or open the repo page in a browser
# Via CLI instead (requires gh or glab installed and authenticated):
gh pr create --base main --head feature/new-login --title "Add new login form" --fill
# GitLab equivalent:
glab mr create --source-branch feature/new-login --target-branch main --title "Add new login form"

# 7. After PR is approved and merged, clean up
git checkout main
git pull origin main
git branch -d feature/new-login
```

## 19. Reflog (Recovering Lost Work)

```bash
# Show a log of everywhere HEAD has pointed (commits, resets, checkouts, etc.)
git reflog

# Recover a "lost" commit after a hard reset or deleted branch
git checkout <commit-hash-from-reflog>

# Restore a branch to where it was before a bad reset
git reset --hard HEAD@{1}

# Clear old reflog entries (rarely needed; entries expire automatically)
git reflog expire --expire=now --all
```

## 20. Submodules

```bash
# Add a repo as a submodule
git submodule add https://github.com/username/lib.git path/to/lib

# Clone a repo including its submodules
git clone --recurse-submodules https://github.com/username/repo.git

# Initialize submodules after a normal clone
git submodule init
git submodule update

# Do both in one step
git submodule update --init --recursive

# Pull latest changes for all submodules
git submodule update --remote

# Remove a submodule
git submodule deinit path/to/lib
git rm path/to/lib
```

## 21. Worktrees

```bash
# Add a new worktree for a branch (lets you check out multiple branches at once)
git worktree add ../feature-folder feature-name

# Add a worktree with a new branch
git worktree add -b feature-name ../feature-folder main

# List all worktrees
git worktree list

# Remove a worktree
git worktree remove ../feature-folder

# Clean up stale worktree references
git worktree prune
```

## 22. Aliases & Global Ignore

```bash
# Create a shorthand alias for a command
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.lg "log --oneline --graph --all"
# Usage afterward: git st, git co main, git lg

# Set a global .gitignore for patterns across all repos (e.g. OS/editor files)
git config --global core.excludesFile ~/.gitignore_global

# Set the default pull behavior (merge vs rebase) globally
git config --global pull.rebase false
```

## 23. Renaming, Removing & Archiving

```bash
# Rename or move a tracked file
git mv oldname.txt newname.txt

# Remove a tracked file (from working directory and staging)
git rm filename.txt

# Remove a file from Git but keep it on disk
git rm --cached filename.txt

# Remove a whole directory
git rm -r some-directory

# Export the repo (or a branch) as a zip/tar archive, no .git history
git archive --format=zip -o project.zip main
```
