## 📊 Core Concepts Matrix

| Concept | Scope | Key Characteristic | Core Command |
|---|---|---|---|
| Repository | Storage | Local machine or hosted on a server | git clone |
| Commit | History | Immutable snapshot identified by a unique hash | git commit |
| Branch | Isolation | Independent timeline to build features safely | git checkout -b |
| Merging | Integration | Combines different timelines and resolves conflicts | git merge |

------------------------------
## 🔄 The Three States Architecture
Git filters your files through three internal zones before saving them permanently:

[ Working Directory ] ───( git add )───> [ Staging Area ] ───( git commit )───> [ Repository ]
   (Untracked/Modified)                     (Prepared Files)                       (.git History)


* Working Directory: The actual project folder on your computer. Changes here are unsafe and untracked.
* Staging Area (Index): A middle sandbox to selectively preview what goes into your next save point.
* Repository (.git): The highly optimized, encrypted local database storing final compressed snapshots.

------------------------------
## 🚀 Standard Team Workflow
Follow these chronological steps to build a feature and collaborate cleanly:

* Step 1: Download

git clone git@github.com:username/repository.git

* Step 2: Isolate

git checkout -b feature-branch

* Step 3: Stage

git add <file-name>

* Step 4: Snapshot

git commit -m "Add new feature"

* Step 5: Publish

git push origin feature-branch

* Step 6: Sync

git checkout main && git pull origin main

* Step 7: Cleanup

git branch -d feature-branch


------------------------------
## ☁️ Cloud Hosting Comparison

* GitHub
* Owned by Microsoft.
   * Home to open-source software.
   * Offers static hosting via GitHub Pages.
* GitLab
* Built as an all-in-one DevOps platform.
   * Features native, robust CI/CD automation pipelines.
   * Allows self-hosting on private corporate servers.
* Bitbucket
* Owned by Atlassian.
   * Connects natively into enterprise tools like Jira and Trello.
   * Tailored for secure, commercial private team workspaces.

Tell me if you would like to practice resolving a merge conflict, configure your user identity details, or set up an SSH key for GitHub.

