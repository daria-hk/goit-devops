1. Resource Status

```
kubectl get all -n jenkins
kubectl get all -n argocd
kubectl get all -n monitoring
```

![Resource Status](images/Resource-status.png)

2. Service availability check

```
kubectl port-forward svc/argocd-server 8081:443 -n argocd
```

![ArgoCD Port](images/argocd-port.png)

```
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

![Grafana Port](images/grafana-port.png)

```
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
```

![Jenkins Port](images/jenkins-port.png)

3. Prometheus is available locally

![Prometheus](images/prometheus.png)

4. Grafana is available locally

![Grafana Dashboard](images/grafana.png)
![Grafana Dashboard List](images/grafana-dashboard-list.png)

