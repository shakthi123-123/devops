# 🐙 The Ultimate Git Version Control & Deployment Manual

A comprehensive, production-grade command playbook and historical tracking reference sheet for Git engine configuration, local staging workflows, branching architectures, remote synchronization, and advanced state restoration.

**⚙️ Setup & Configuration**

### Set Global Commit Author Profiling Username
```bash
git config --global user.name "Your Name"
```

### Set Global Commit Author Profiling Email Address
```bash
git config --global user.email "you@example.com"
```

### Set Default Visual Studio Code Interface Text Editor Engine
```bash
git config --global core.editor "code --wait"
```

### Display All Active Environmental Configuration Rules
```bash
git config --list
```

### Pull Up the Local System Manual for a Specific Subcommand
```bash
git help config
```

**📂 Project Initialization & Bootstrap Operations**

### Instantiate a Brand New Local Repository Workspace Layout
```bash
git init
```

### Clone a Complete Remote Project Architecture and History
```bash
git clone https://github.com
```

**🛠️ Workspace Auditing & Staging Index Indexing**

### Audit Project Tree Working Directory State Changes
```bash
git status
```

### Transfer Specific Modified File Layers Into Staging Index
```bash
git add file.txt
```

### Transfer Every Local File Modification into Staging Index
```bash
git add .
```

### Interactively Audit and Select Code Blocks (Hunks) to Stage
```bash
git add -p
```

### Evict File and Discard Tracking From Staging and Disk
```bash
git rm file.txt
```

### Remove File Tracking Indexes While Retaining Files On Local Disk
```bash
git rm --cached file.txt
```

### Re-route File Path Locations or Rename Assets and Stage Instantly
```bash
git mv old_path.txt new_path.txt
```

**💾 Immutable Snapshot Archiving (Committing)**

### Commit Staged Snapshots to the Permanent Historical Timeline
```bash
git commit -m "feat: implement container telemetry processing pipelines"
```

### Automatically Stage Tracked Modifications and Commit Instantly
```bash
git commit -am "fix: correct service mesh validation failure loops"
```

### Amend and Re-write the Metadata Content of the Absolute Last Commit
```bash
git commit --amend
```

**🌿 Feature Isolation & Branching Topologies**

### List Active Local Workspace Feature Branches
```bash
git branch
```

### List Tracked Local and Remote Upstream Branches Simultaneously
```bash
git branch -a
```

### Instantiate a New Head Feature Branch at the Current State
```bash
git branch feature-worker-nodes
```

### Safely Context-Switch Working Directories to Another Branch
```bash
git switch feature-worker-nodes
```

### Create a New Feature Branch and Context-Switch Instantly
```bash
git switch -c feature-load-balancers
```

### Merge Target Feature History into the Active Checked-Out Branch
```bash
git merge feature-worker-nodes
```

### Delete a Fully Merged Feature Branch Safely
```bash
git branch -d feature-worker-nodes
```

### Force Terminate and Discard an Unmerged Local Branch
```bash
git branch -D feature-load-balancers
```

**🔄 Remote Infrastructure Synchronization**

### Map a Remote Endpoint Infrastructure Target to a Local Alias Identifier
```bash
git remote add origin https://github.com
```

### List Configured Remote Target URLs and Transport Vectors
```bash
git remote -v
```

### Download Upstream Historical Timelines Without Mutating Local Files
```bash
git fetch origin
```

### Download Remote Codebases and Merges State Into Current Branch Instantly
```bash
git pull
```

### Upload Local State Commit Logs to Remote Repositories
```bash
git push origin main
```

### Push Local Branches and Lock In Upstream Tracking Associations
```bash
git push -u origin main
```

**🔍 Historical Chronology Auditing & Code Diffs**

### Review Extended Chronological Commit Signatures
```bash
git log
```

### Condense Historical Logs Into Scannable Single-Line Entries
```bash
git log --oneline
```

### Draw ASCII Branch Trees Summarizing Complete Repository Histories
```bash
git log --graph --oneline --all
```

### Audit Lines Modified In Working Directories Before Staging Takes Place
```bash
git diff
```

### Compare Current Staged Configurations Against the Last Commit Head
```bash
git diff --staged
```

### Unpack Complete Metadata Profiles and Code Changes of a Commit Hash
```bash
git show a1b2c3d
```

### Isolate File Modification Histories and Authors Line-by-Line
```bash
git blame deployment.yaml
```

**📦 Working State Shelving (Stashing)**

### Shelve Current Workspace Uncommitted States into Temporary Storage
```bash
git stash
```

### List Stored Working Configurations Staged on the Stash Stack
```bash
git stash list
```

### Pop the Top-Most Shelved State Back Into the Active Workspace Index
```bash
git stash pop
```

### Discard the Top-Most Shelved State Layer from the Stash Stack
```bash
git stash drop
```

**⚠️ State Deselection & History Reversal Controls**

### Revert Unstaged Working File Mutations Back to Last Commit State
```bash
git restore deployment.yaml
```

### Evict Staged Changes Back to Unstaged Workspace Cache Storage
```bash
git restore --staged deployment.yaml
```

### Drop Specific File Allocations out of Staging Directories
```bash
git reset deployment.yaml
```

### Rewind Local Head History by Exactly One Commit (Preserves Files)
```bash
git reset HEAD~1
```
