# Monitoring Setup with Prometheus & Grafana

## Overview

This project uses **Prometheus** for metrics collection and **Grafana** for visualization to provide complete observability of the Kubernetes cluster and applications.

## Architecture

- **Prometheus Server**: Collects and stores metrics from configured targets
- **Prometheus Exporters**: Expose metrics in Prometheus format (node-exporter, kube-state-metrics)
- **Service Discovery**: Automatically discovers Kubernetes resources to monitor
- **Alertmanager**: Handles alerts and notifications
- **Grafana**: Provides beautiful dashboards and visualization

## Installation

### Prerequisites

- Kubernetes cluster with kubectl access
- Helm 3.x installed

### Step 1: Add Helm Repositories

```bash
# Add Prometheus community charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Add Grafana charts
helm repo add grafana https://grafana.github.io/helm-charts

# Update repositories
helm repo update
```

### Step 2: Create Monitoring Namespace

```bash
kubectl create namespace monitoring
```

### Step 3: Install Prometheus

```bash
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set alertmanager.persistentVolume.enabled=false \
  --set server.persistentVolume.enabled=false
```

**Components installed:**

- Prometheus Server
- Alertmanager
- Node Exporter
- Kube State Metrics
- Pushgateway

### Step 4: Install Grafana

```bash
helm install grafana grafana/grafana \
  --namespace monitoring \
  --set adminPassword=admin123
```

### Step 5: Verify Installation

```bash
kubectl get all -n monitoring
```

You should see:

- `prometheus-server`
- `prometheus-alertmanager`
- `prometheus-node-exporter`
- `grafana`

## Accessing Services

### Prometheus UI

```bash
# Port forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-server 9090:80
```

Open browser: **http://localhost:9090**

**Key features:**

- **Status → Targets**: View all monitored endpoints and their health status
- **Status → Service Discovery**: See auto-discovered Kubernetes resources
- **Graph**: Execute PromQL queries and visualize metrics

### Grafana UI

```bash
# Get admin password
kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode

# Port forward Grafana
kubectl port-forward -n monitoring svc/grafana 3000:80
```

Open browser: **http://localhost:3000**

- **Username**: `admin`
- **Password**: (from command above or `admin123` if set during install)

## Configure Grafana

### 1. Add Prometheus Data Source

1. Click **⚙️ Configuration** → **Data sources**
2. Click **Add data source**
3. Select **Prometheus**
4. Configure:
   - **Name**: `Prometheus`
   - **URL**: `http://prometheus-server.monitoring.svc:80`
   - **Access**: Server (default)
5. Click **Save & test** ✅

### 2. Import Dashboards

Grafana has thousands of pre-built dashboards available at:
👉 **https://grafana.com/grafana/dashboards**

**Recommended dashboards:**

| Dashboard                         | ID   | Description                  |
| --------------------------------- | ---- | ---------------------------- |
| Kubernetes Cluster Monitoring     | 7249 | Complete cluster overview    |
| Kubernetes Pod Monitoring         | 6417 | Pod-level metrics and health |
| Node Exporter Full                | 1860 | Detailed node metrics        |
| Kubernetes Deployment Statefulset | 8588 | Workload monitoring          |

**To import:**

1. Click **+** → **Import dashboard**
2. Enter dashboard ID (e.g., `7249`)
3. Click **Load**
4. Select **Prometheus** as data source
5. Click **Import** ✅

## Key Metrics Examples

### Prometheus Queries (PromQL)

```promql
# Check if targets are up
up

# HTTP request rate (5min average)
rate(http_requests_total[5m])

# CPU usage by pod
rate(container_cpu_usage_seconds_total[5m])

# Memory usage by pod
container_memory_usage_bytes

# Pod restart count
kube_pod_container_status_restarts_total

# HPA current replicas
kube_horizontalpodautoscaler_status_current_replicas
```

## Monitoring Kubernetes Resources

Prometheus automatically discovers and monitors:

### kubernetes-apiservers

- **Endpoint**: `https://10.0.x.x:443/metrics`
- **Metrics**: API server performance, request rates, errors

### kubernetes-nodes

- **Endpoint**: Proxied through Kubernetes API
- **Metrics**: CPU, memory, disk, network per node
- **Labels**: instance type, availability zone, architecture

### kubernetes-pods

- **Metrics**: Container resources, restarts, states
- **Labels**: namespace, pod name, container name

### kubernetes-service-endpoints

- **Metrics**: Application-specific metrics exposed via `/metrics`

## Service Discovery

Prometheus uses `kubernetes_sd_config` to automatically discover:

- API servers
- Nodes
- Pods
- Services
- Endpoints
- Ingresses

**View discovered targets:**

- Prometheus UI → **Status** → **Service Discovery**

## Alerting (Optional)

Alertmanager is included and can be configured for:

- Slack notifications
- Email alerts
- PagerDuty integration
- Webhook callbacks

Configure alerts in Prometheus `values.yaml` under `serverFiles.alerts`.

## Troubleshooting

### Prometheus Targets Down

```bash
# Check Prometheus logs
kubectl logs -n monitoring deployment/prometheus-server

# Check target health in UI
# Prometheus → Status → Targets
```

### Grafana Cannot Connect to Prometheus

1. Verify Prometheus service exists:

   ```bash
   kubectl get svc -n monitoring prometheus-server
   ```

2. Test connectivity from Grafana pod:
   ```bash
   kubectl exec -it -n monitoring deployment/grafana -- \
     curl http://prometheus-server.monitoring.svc:80/-/healthy
   ```

### No Metrics Appearing

1. Check if metrics-server is installed:

   ```bash
   kubectl get deployment metrics-server -n kube-system
   ```

2. Verify exporters are running:
   ```bash
   kubectl get pods -n monitoring | grep exporter
   ```

## Production Considerations

For production use, enable persistent storage:

```bash
helm upgrade prometheus prometheus-community/prometheus \
  --namespace monitoring \
  --set server.persistentVolume.enabled=true \
  --set server.persistentVolume.size=50Gi \
  --set alertmanager.persistentVolume.enabled=true
```

## Useful Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
- [Grafana Dashboards Library](https://grafana.com/grafana/dashboards/)

## Summary

✅ **Prometheus**: Installed and collecting metrics from Kubernetes cluster  
✅ **Grafana**: Installed with Prometheus data source configured  
✅ **Service Discovery**: Auto-discovering Kubernetes resources  
✅ **Dashboards**: Ready to import and customize  
✅ **Monitoring**: Complete observability of infrastructure and applications

**Status**: Production-ready monitoring stack 🚀
