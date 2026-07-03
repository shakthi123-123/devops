Git is built as a Distributed Version Control System (DVCS). Unlike centralized systems that rely on a single server, Git provides every developer with a full copy of the project history on their local machine. [1, 2, 3]  
Its internal architecture relies on two core design principles: a Three-Stage Workflow Layout (how you manage code) and an Immutable Object Database (how Git stores data). 
🧱 The Three-Stage Architecture 
Git tracks your project using three major local environments before interacting with external servers. 

• Working Directory (Workspace): This is the active directory on your operating system where you create, modify, and delete files. Git sees these modifications, but they are not yet safely tracked or locked into history. 
• Staging Area (Index): A single binary file located at . It acts as a prep area or a "shopping cart". Running  takes a snapshot of your files in their current state and prepares them for the next commit. 
• Local Repository ( directory): This is Git's permanent database containing all historical snapshots, metadata, and references. Running  moves the staged content here, mapping it permanently into the historical timeline. 

🗄️ The Internal Data Model (Git Objects) 
Behind the scenes, Git functions as a content-addressable key-value store. Everything stored inside the  folder is compressed, encrypted, and indexed by a unique 40-character SHA-1 checksum hash. 
There are four primary primitives in this object database: 

| Object Type | Role | What It Contains  |
| --- | --- | --- |
| Blob | File Content | Stores raw data of a file. It does not store filenames or directory paths. If two identical files exist in different folders, Git saves only one blob.  |
| Tree | Directory Structure | Represents folders. A Tree object lists pointers to Blobs (files) and other Sub-Trees (folders), alongside their filenames and execution permissions.  |
| Commit | History Snapshot | A permanent record pointing to a single top-level Tree object. It contains metadata: author, date, message, and a pointer to the previous commit (Parent Hash).  |
| Tag | Code Milestone | A human-readable identifier (like ) pinned to a specific commit hash.  |

⛓️ How Snapshots Connect Under the Hood 
When you issue a , Git constructs a Directed Acyclic Graph (DAG) of your project's life. 

1. Snapshots, Not Deltas: Unlike older version control applications that store historical differences line-by-line, Git stores whole mini-filesystems. If a file does not change between commits, Git points directly to the existing blob from the previous snapshot to minimize disk usage. 
2. References (Refs): Branches and tags are not distinct heavy folders; they are simply lightweight, text-file pointers targeting specific commit hashes inside . 
3. The HEAD Pointer: A distinct internal reference () that simply tracks which branch or specific commit your working directory is currently pointed to. 

🌐 The Remote Collaboration Layer 
Because Git is fully local-first, sharing code relies on a network transport layer. Remote servers (such as GitHub, GitLab, or bitbucket) manage a copy of the exact same object graph. 

• : Transfers your local commits, trees, and blobs up to the remote server graph. 
• : Downloads new metadata and commits from the remote server into your local  repository, without changing your active working directory files. 
• : A compound command that runs  immediately followed by  to integrate the remote changes directly into your active workspace. 
[13] https://en.wikipedia.org/wiki/Git

