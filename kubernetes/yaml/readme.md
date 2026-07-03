
```bash
apiVersion: v1
kind: Namespace
metadata:
  name: new-namespace
```
#### Apply the configuration file to your active cluster
```bash
kubectl apply -f namespace.yaml
```
#### List all namespaces in the cluster
```bash
kubectl get namespaces
```
#### Switch your current active terminal context permanently
```bash
kubectl config set-context --current --namespace=my-namespace
```
