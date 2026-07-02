# 🚀 Git Cheat Sheet

A clean, copy-paste reference guide for essential Git commands.

---

## 📂 1. Setting Up a Repository

**Initialize a new local repository**
```bash
git init
```

**Clone an existing online repository**
```bash
git clone <repository_url>
```

---

## 💾 2. Saving Changes

**Check the status of your files**
```bash
git status
```

**Stage a specific file**
```bash
git add <filename>
```

**Stage all modified and new files**
```bash
git add .
```

**Commit staged changes with a message**
```bash
git commit -m "Your commit message here"
```

---

## 🚚 3. Moving & Deleting Files

**Move or rename a file**
```bash
git mv <old_path> <new_path>
```

**Delete a file completely**
```bash
git rm <filename>
```

**Stop tracking a file but keep it locally**
```bash
git rm --cached <filename>
```

---

## ☁️ 4. Syncing with GitHub

**Link local folder to GitHub**
```bash
git remote add origin <repository_url>
```

**Pull latest online updates**
```bash
git pull origin main
```

**First-time push to set default branch**
```bash
git push -u origin main
```

**Standard push for existing branches**
```bash
git push origin main
```

---

## 🌿 5. Branching & Merging

**List all local branches**
```bash
git branch
```

**Create a new branch**
```bash
git branch <branch_name>
```

**Switch to an existing branch**
```bash
git checkout <branch_name>
```

**Create and switch to a new branch instantly**
```bash
git checkout -b <branch_name>
```

**Merge a branch into your current branch**
```bash
git merge <branch_name>
```

**Delete a merged branch**
```bash
git branch -d <branch_name>
```
