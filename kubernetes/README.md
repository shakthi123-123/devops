A Kubernetes (K8s) cluster relies on a highly decoupled, client-server architecture,
It splits responsibilities between a management layer and an execution layer 

The Two Core Layers+-------------------------------------------------------------+

|                        CONTROL PLANE                        |
|   +------------------+                   +--------------+   |
|   |  kube-apiserver  |<----------------->|     etcd     |   |
|   +--------+---------+                   +--------------+   |
|            |                                                |
|            v                                                |
|   +------------------+                   +--------------+   |
|   |  kube-scheduler  |                   |  controller  |   |
|   +------------------+                   +--------------+   |
+------------+------------------------------------------------+
             |
             | (Communicates via TLS)
             v
+-------------------------------------------------------------+

|                        WORKER NODE                          |
|   +------------------+                   +--------------+   |
|   |     kubelet      |                   |  kube-proxy  |   |
|   +--------+---------+                   +--------------+   |
|            |                                                |
|            v                                                |
|   +------------------+                                      |
|   |Container Runtime |                                      |
|   |  +------------+  |                                      |
|   |  |   Pods     |  |                                      |
|   |  +------------+  |                                      |
|   +------------------+                                      |
+-------------------------------------------------------------+

1. The Control Plane (The Brain) The control plane makes global decisions about the cluster. It detects and responds to cluster events to maintain your desired configuration. 

• : The front door for all communications. It exposes the HTTP REST API used by external users and internal components. 
• : A highly available, distributed key-value database. It serves as the single source of truth for all cluster state and data. 
• : The matchmaker for workloads. It watches for newly created Pods and assigns them to a healthy node based on resource requirements. 
• : The core driving force. It runs distinct background controller processes to continuously drive the current state toward the desired state. 
• : The cloud infrastructure bridge. It embeds cloud-specific control logic to manage resources like cloud load balancers and storage volumes. 

2. Worker Nodes (The Muscle) Worker nodes maintain running workloads and provide the active Kubernetes runtime environment. 

• : The on-site manager. It is an agent running on every node that ensures containers described in configurations are running and healthy. 
• : The network operator. It maintains network rules on nodes to allow network communication to Pods from inside or outside the cluster. 
• Container Runtime: The software that executes containers. Kubernetes supports industry runtimes like  and . [4, 5, 7, 8, 9]  

Core Data Unit: The Pod 
A Pod is the smallest deployable unit you can create and manage in Kubernetes. 

• It wraps one or more tightly coupled containers. 
• Containers within a single Pod share the same network IP, port space, and storage volumes. [9, 10, 11]  

Crucial Cluster Add-ons 
Add-ons use Kubernetes resources to extend the capabilities of your cluster. 

• CoreDNS: Provides flexible name resolution and service discovery across the cluster. 
• CNI Plugin: Software like Calico or Cilium that implements the Container Network Interface to handle cross-node network routing. 
• Metrics Server: Aggregates resource usage data to assist with auto-scaling metrics. [3, 5, 12, 13, 14]  

Why This Design Works 
The components never talk directly to each other. They rely exclusively on the central  to store state in  and watch for state changes. This decoupling ensures high availability and fault tolerance, as any broken component can be safely restarted without crashing the rest of the cluster. 
For complete implementations and structural variations, you can view the official documentation on Kubernetes Cluster Architecture. 
If you want to dive deeper, let me know if you would like to explore how a deployment flows through these components, look at high-availability setup patterns, or choose a CNI plugin. 
