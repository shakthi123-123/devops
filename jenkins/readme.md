# Jenkins: Complete Step-by-Step Guide

A practical guide covering installation, initial setup, creating jobs, building CI/CD pipelines, and key best practices.

---

## Table of Contents

1. [Installing Jenkins](#1-installing-jenkins)
2. [Initial Setup Wizard](#2-initial-setup-wizard)
3. [Jenkins Concepts Overview](#3-jenkins-concepts-overview)
4. [Creating Your First Freestyle Job](#4-creating-your-first-freestyle-job)
5. [Building a Declarative Pipeline (Jenkinsfile)](#5-building-a-declarative-pipeline-jenkinsfile)
6. [Connecting Jenkins to GitHub](#6-connecting-jenkins-to-github)
7. [Managing Plugins](#7-managing-plugins)
8. [Managing Credentials](#8-managing-credentials)
9. [Best Practices](#9-best-practices)
10. [Cheat Sheet](#10-cheat-sheet)

---

## 1. Installing Jenkins

### Option A — Ubuntu/Debian (apt)

```bash
# Install Java (Jenkins requires Java 17 or 21)
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre

# Add the Jenkins repository key
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# Add the Jenkins apt repository
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  "https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Install Jenkins
sudo apt update
sudo apt install -y jenkins

# Start and enable the service
sudo systemctl enable jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

### Option B — Docker (fastest for testing)

```bash
docker run -d \
  --name jenkins \
  -p 8080:8080 -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  jenkins/jenkins:lts
```

### Option C — macOS (Homebrew)

```bash
brew install jenkins-lts
brew services start jenkins-lts
```

### Option D — Windows

1. Download the `.msi` installer from [jenkins.io/download](https://www.jenkins.io/download/).
2. Run the installer and follow the setup wizard.
3. Jenkins installs itself as a Windows service and starts automatically.

### Verify it's running

Open a browser and go to:
```
http://localhost:8080
```

---

## 2. Initial Setup Wizard

### Step 2.1 — Unlock Jenkins

On first launch, Jenkins shows an "Unlock Jenkins" screen asking for an initial admin password. Retrieve it:

```bash
# apt install
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Docker install
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

Paste the password into the browser prompt.

### Step 2.2 — Install plugins

Choose **"Install suggested plugins"** (recommended for most setups) — this installs Git, Pipeline, GitHub, and other commonly needed plugins automatically.

### Step 2.3 — Create the first admin user

Fill in:
- Username
- Password
- Full name
- Email address

### Step 2.4 — Set the Jenkins URL

Confirm or update the instance URL (e.g. `http://localhost:8080/` or your server's domain), then click **Save and Finish**.

### Step 2.5 — Start using Jenkins

Click **Start using Jenkins** to land on the main dashboard.

---

## 3. Jenkins Concepts Overview

| Term | Meaning |
|---|---|
| **Job / Project** | A single task Jenkins runs (build, test, deploy) |
| **Freestyle Job** | A job configured entirely through the UI (no code) |
| **Pipeline** | A job defined as code (Groovy-based `Jenkinsfile`) |
| **Build** | One execution/run of a job |
| **Node / Agent** | A machine that executes build steps (the "controller" itself, or remote agents) |
| **Executor** | A slot on a node that can run one build at a time |
| **Workspace** | The directory where a job's files are checked out and built |
| **Plugin** | An add-on that extends Jenkins functionality |
| **Credentials** | Securely stored secrets (tokens, SSH keys, passwords) used by jobs |

---

## 4. Creating Your First Freestyle Job

### Step 4.1 — Start a new job

From the dashboard, click **New Item**.

### Step 4.2 — Name it and choose a type

1. Enter a name, e.g. `hello-world-job`.
2. Select **Freestyle project**.
3. Click **OK**.

### Step 4.3 — Configure the source (optional for this example)

Under **Source Code Management**, choose **None** for now (we'll connect Git in Section 6).

### Step 4.4 — Add a build step

Scroll to **Build Steps** → **Add build step** → **Execute shell** (Linux/macOS) or **Execute Windows batch command** (Windows).

```bash
echo "Hello from Jenkins!"
date
```

### Step 4.5 — Save and run

1. Click **Save**.
2. Click **Build Now** (left sidebar).
3. Under **Build History**, click the build number → **Console Output** to see the log.

---

## 5. Building a Declarative Pipeline (Jenkinsfile)

Pipelines are the modern, code-based way to define CI/CD in Jenkins. They're written in a `Jenkinsfile`, typically committed alongside your application code.

### Step 5.1 — Write a basic Jenkinsfile

Create a file named `Jenkinsfile` in your project's root:

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out code...'
                checkout scm
            }
        }

        stage('Build') {
            steps {
                echo 'Building application...'
                sh 'echo "Build step goes here"'
            }
        }

        stage('Test') {
            steps {
                echo 'Running tests...'
                sh 'echo "Test step goes here"'
            }
        }

        stage('Deploy') {
            steps {
                echo 'Deploying application...'
                sh 'echo "Deploy step goes here"'
            }
        }
    }

    post {
        success {
            echo 'Pipeline succeeded!'
        }
        failure {
            echo 'Pipeline failed.'
        }
        always {
            echo 'Pipeline finished (runs regardless of outcome).'
        }
    }
}
```

### Step 5.2 — Create a Pipeline job in Jenkins

1. **New Item** → enter a name → select **Pipeline** → **OK**.
2. Scroll to the **Pipeline** section.
3. Under **Definition**, choose:
   - **Pipeline script** (paste the Jenkinsfile content directly), or
   - **Pipeline script from SCM** (point Jenkins at your Git repo — recommended).

### Step 5.3 — Configure "Pipeline script from SCM"

- **SCM**: Git
- **Repository URL**: `https://github.com/your-org/your-repo.git`
- **Branch**: `*/main`
- **Script Path**: `Jenkinsfile` (default)

### Step 5.4 — Save and run

Click **Save** → **Build Now**. Jenkins pulls your repo, finds the `Jenkinsfile`, and runs each stage — visualized as a stage graph in the UI.

### Step 5.5 — Add real build logic (example: Node.js app)

```groovy
pipeline {
    agent any

    environment {
        NODE_ENV = 'production'
    }

    stages {
        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Install Dependencies') {
            steps { sh 'npm install' }
        }

        stage('Run Tests') {
            steps { sh 'npm test' }
        }

        stage('Build') {
            steps { sh 'npm run build' }
        }

        stage('Archive Artifacts') {
            steps {
                archiveArtifacts artifacts: 'dist/**', fingerprint: true
            }
        }
    }
}
```

### Step 5.6 — Parallel stages (speed up independent tasks)

```groovy
stage('Test Suite') {
    parallel {
        stage('Unit Tests') {
            steps { sh 'npm run test:unit' }
        }
        stage('Lint') {
            steps { sh 'npm run lint' }
        }
    }
}
```

### Step 5.7 — Conditional stages

```groovy
stage('Deploy to Production') {
    when {
        branch 'main'
    }
    steps {
        sh './deploy.sh production'
    }
}
```

---

## 6. Connecting Jenkins to GitHub

### Step 6.1 — Generate a GitHub personal access token

1. On GitHub: **Settings → Developer settings → Personal access tokens → Generate new token**.
2. Grant `repo` and `admin:repo_hook` scopes.
3. Copy the token (you won't see it again).

### Step 6.2 — Add the token as a Jenkins credential

See [Section 8](#8-managing-credentials) below.

### Step 6.3 — Set up a webhook for automatic builds

1. In your GitHub repo: **Settings → Webhooks → Add webhook**.
2. **Payload URL**: `http://<your-jenkins-url>/github-webhook/`
3. **Content type**: `application/json`
4. **Events**: choose "Just the push event" (or add pull requests, etc.)
5. Save.

### Step 6.4 — Enable the trigger in your Jenkins job

In the job's configuration → **Build Triggers** → check **GitHub hook trigger for GITScm polling**.

Now every push to the repo automatically triggers a Jenkins build.

---

## 7. Managing Plugins

### Step 7.1 — Open the Plugin Manager

**Manage Jenkins → Plugins**

### Step 7.2 — Install a plugin

1. Go to the **Available plugins** tab.
2. Search (e.g. "Docker Pipeline", "Slack Notification", "Blue Ocean").
3. Check the box → **Install without restart** (or **Download now and install after restart**).

### Step 7.3 — Commonly useful plugins

| Plugin | Purpose |
|---|---|
| Git / GitHub | Source control integration |
| Pipeline | Enables `Jenkinsfile`-based pipelines |
| Blue Ocean | Modern visual pipeline UI |
| Docker Pipeline | Build/run Docker containers in pipelines |
| Credentials Binding | Securely inject secrets into build steps |
| Slack Notification | Post build results to Slack |
| JUnit | Publish test result reports |

---

## 8. Managing Credentials

### Step 8.1 — Add a credential

**Manage Jenkins → Credentials → System → Global credentials → Add Credentials**

Choose a kind:
- **Username with password** (e.g. GitHub token as password)
- **SSH Username with private key**
- **Secret text** (e.g. an API key)
- **Secret file**

### Step 8.2 — Use a credential in a Pipeline

```groovy
pipeline {
    agent any
    stages {
        stage('Deploy') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-token',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh 'echo "Using credentials securely"'
                }
            }
        }
    }
}
```

> Credentials referenced this way are automatically masked in console output.

---

## 9. Best Practices

### 9.1 — Keep pipelines in source control

Store the `Jenkinsfile` in the same repo as your application code ("Pipeline as Code") rather than pasting scripts into the Jenkins UI.

### 9.2 — Use declarative syntax over scripted

Declarative pipelines (the `pipeline { }` block style shown above) are easier to read, validate, and maintain than older scripted (`node { }`) syntax.

### 9.3 — Fail fast, fail loud

Add proper exit codes and test reporting so broken builds are obvious:
```groovy
post {
    always {
        junit 'test-results/**/*.xml'
    }
}
```

### 9.4 — Use agents/nodes for isolation

Don't run everything on the Jenkins controller. Use dedicated agents (physical, VM, or Docker-based) for actual build/test work:
```groovy
pipeline {
    agent {
        docker { image 'node:20' }
    }
    ...
}
```

### 9.5 — Set build timeouts

Prevent stuck jobs from hogging executors indefinitely:
```groovy
options {
    timeout(time: 30, unit: 'MINUTES')
}
```

### 9.6 — Clean workspace between builds

```groovy
post {
    always {
        cleanWs()
    }
}
```

### 9.7 — Back up Jenkins regularly

Back up `$JENKINS_HOME` (job configs, credentials, plugins, build history) — consider the **ThinBackup** plugin or scheduled snapshots if running in a VM/container.

### 9.8 — Limit plugin sprawl

Only install plugins you actually use — each one is a maintenance and security surface.

### 9.9 — Use least-privilege credentials

Scope tokens (e.g. GitHub PATs) to only the repos/permissions they need, and rotate them periodically.

---

## 10. Cheat Sheet

| Action | Where in UI |
|---|---|
| Create a job | Dashboard → New Item |
| Run a build | Job page → Build Now |
| View logs | Build number → Console Output |
| Edit job config | Job page → Configure |
| Install plugins | Manage Jenkins → Plugins |
| Add credentials | Manage Jenkins → Credentials |
| View system logs | Manage Jenkins → System Log |
| Manage nodes/agents | Manage Jenkins → Nodes |
| Restart Jenkins | `http://<jenkins-url>/restart` or `systemctl restart jenkins` |

### Common CLI commands (host running Jenkins)

```bash
sudo systemctl start jenkins
sudo systemctl stop jenkins
sudo systemctl restart jenkins
sudo systemctl status jenkins
sudo journalctl -u jenkins -f     # tail logs
```

---

### Next steps

- Explore **Blue Ocean** for a more visual pipeline editor/viewer.
- Look into **Multibranch Pipelines** to auto-create a pipeline per Git branch/PR.
- Consider **Jenkins Configuration as Code (JCasC)** to manage Jenkins' own setup declaratively via YAML.
