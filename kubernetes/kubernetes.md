# ☸️ Kubernetes Cluster Architecture

<p align="center">
  <img src="https://shields.io" alt="K8s Banner" />
</p>

---

<!-- SECTION 1: GLOBAL LAYOUT OVERVIEW -->
<table width="100%">
  <tr>
    <!-- Left Column: Core Definition -->
    <td width="40%" valign="top">
      <h3>📌 High-Level Architecture</h3>
      <p>A Kubernetes cluster consists of a centralized <strong>Control Plane</strong> and a fleet of <strong>Worker Nodes</strong> running containerized applications.</p>
      <ul>
        <li><strong>Control Plane:</strong> Makes global cluster decisions.</li>
        <li><strong>Worker Nodes:</strong> Host execution layers (Pods).</li>
        <li><strong>Availability:</strong> Spread across multiple machines for high fault tolerance.</li>
      </ul>
    </td>
    <!-- Right Column: Visual Component Flow -->
    <td width="60%" valign="top">
      <h3>🗺️ Structural Hierarchy</h3>
      <pre>
┌────────────────────────────────────────────────────────┐
│                    CONTROL PLANE                       │
│  [API Server]  ↔  [etcd]  ↔  [Scheduler]  ↔  [Managers]│
└───────────────────────────┬────────────────────────────┘
                            │
              ┌─────────────┴─────────────┐
              ▼                           ▼
      ┌───────────────┐           ┌───────────────┐
      │  WORKER NODE  │           │  WORKER NODE  │
      │ [kubelet]     │           │ [kubelet]     │
      │ [kube-proxy]  │           │ [kube-proxy]  │
      │ [Runtime]     │           │ [Runtime]     │
      └───────────────┘           └───────────────┘
      </pre>
      <p align="center"><small><em>Figure 1. Kubernetes cluster components communication scheme.</em></small></p>
    </td>
  </tr>
</table>

---

<!-- SECTION 2: THREE-COLUMN CONTROL PLANE LAYOUT -->
## 🧠 1. The Control Plane
*Global decision makers managing life-cycles, scheduling tasks, and processing events.*

<table width="100%">
  <tr>
    <!-- COLUMN 1 -->
    <td width="33.3%" valign="top">
      <h4>⚡ kube-apiserver</h4>
      <p>The front-end entry point exposing the Kubernetes API. Scales horizontally across multiple instances to balance high traffic workloads.</p>
      <h4>🗄️ etcd</h4>
      <p>A highly-available, consistent key-value data store used exclusively as Kubernetes' backing engine for all cluster blueprints.</p>
    </td>
    <!-- COLUMN 2 -->
    <td width="33.3%" valign="top">
      <h4>📅 kube-scheduler</h4>
      <p>Watches for newly generated Pods lacking target hosts and assigns them to optimum nodes based on resource boundaries, policy rules, and data affinity constraints.</p>
    </td>
    <!-- COLUMN 3 -->
    <td width="33.3%" valign="top">
      <h4>⚙️ kube-controller-manager</h4>
      <p>Bundles discrete background automation loops into a single process. Runs:</p>
      <ul>
        <li><strong>Node Controller:</strong> Handles host outages.</li>
        <li><strong>Job Controller:</strong> Tracks ephemeral tasks.</li>
        <li><strong>EndpointSlice:</strong> Maps Services to Pods.</li>
      </ul>
    </td>
  </tr>
  <tr>
    <!-- FULL WIDTH EXPANSION ROW FOR CLOUD CONTROLLER -->
    <td colspan="3" valign="top">
      <h4>☁️ cloud-controller-manager <small>(Optional Provider-Specific Layer)</small></h4>
      <p>Embeds cloud-native logical circuits separating platform-independent operations from cloud-provider interactions. Manages underlying infrastructure parameters like native node tracking loops, platform routing tables, and hardware load balancer engines. <em>(Omitted in bare-metal or local test clusters).</em></p>
    </td>
  </tr>
</table>

---

<!-- SECTION 3: TWO-COLUMN WORKER COMPONENT LAYOUT -->
## 🏗️ 2. Worker Node Components
*Runtime micro-services deployed to every active node machine to maintain healthy application execution spaces.*

<table width="100%">
  <tr>
    <!-- LEFT NODE COMPONENT -->
    <td width="50%" valign="top">
      <h4>🛡️ kubelet</h4>
      <p>An on-host micro-agent listening to inbound <code>PodSpecs</code>. Verifies that user-defined container sets are correctly operational, safe, and healthy. It skips managing processes generated outside native Kubernetes controllers.</p>
    </td>
    <!-- RIGHT NODE COMPONENT -->
    <td width="50%" valign="top">
      <h4>🌐 kube-proxy <small>(Network layer)</small></h4>
      <p>Maintains low-level host OS packet-filtering pipelines and network maps. Orchestrates request routing from network clients directly to matching isolated target Pods. Can be skipped if using a self-forwarding CNI plugin.</p>
    </td>
  </tr>
  <tr>
    <!-- INDUSTRIAL RUNTIME WRAPPER -->
    <td colspan="2" valign="top">
      <h4>📦 Container Runtime Engine</h4>
      <p>The fundamental compute system executing application container filesystems. Interfaces natively via the Container Runtime Interface (CRI). Core examples include <code>containerd</code> and <code>CRI-O</code>.</p>
    </td>
  </tr>
</table>

---

<!-- SECTION 4: HORIZONTAL ADDONS SECTION -->
## 🔌 3. Core Cluster Addons & Plugins
*Namespaced within <code>kube-system</code> to provide platform-wide networking, routing, interface, and metric infrastructure.*

<table width="100%">
  <tr>
    <td width="50%" valign="top">
      <h4>🌐 Network & Discovery Essentials</h4>
      <ul>
        <li><strong>Cluster DNS:</strong> A secondary system DNS serving automated internal service records directly to pods.</li>
        <li><strong>Network Plugins (CNI):</strong> Allocates inter-pod virtual IP networks and implements communication paths.</li>
      </ul>
    </td>
    <td width="50%" valign="top">
      <h4>📊 Operations, Metrics & UI Tools</h4>
      <ul>
        <li><strong>Web UI Dashboard:</strong> A web interface to view, configure, and troubleshoot active cluster assets.</li>
        <li><strong>Resource Monitoring:</strong> Logs generic time-series performance data across containers.</li>
        <li><strong>Logging Engines:</strong> Funnels multi-node system errors into central, searchable databases.</li>
      </ul>
    </td>
  </tr>
</table>

---

## 🔄 4. Deployment Variations
* **Traditional Setup:** Control plane loops run directly inside the machine environment managed as native `systemd` target units.
* **Static Pods Architecture:** Core system binaries execute inside internal runtime sandboxes overseen directly by local node `kubelet` daemons.
