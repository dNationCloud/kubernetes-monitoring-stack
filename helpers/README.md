# Helpers

A set of scripts and configuration files which helps to simplify Kubernetes cluster setup and local development 

## Kubernetes control plane components metrics

The metrics bind addresses of `etcd` and `kube-proxy` control plane components are 
by default bind to the localhost that prometheus instances cannot access. 
Also `scheduler` and `controller-manager` control plane components could have the
same metrics addresses binding in case of K8s deployment on the AWS platform. 
You should expose metrics by changing bind addresses if you want to collect them.

Edit and use `kubeadm_init.yaml` file to configure `kubeadm init` in case of fresh K8s deployment.   

```bash
kubeadm init --config=helpers/kubeadm_init.yaml
```

Manual setup in case of already running K8s deployment.  

* Setup `etcd` metrics bind address
    ```bash
    # On k8s master node
    cd /etc/kubernetes/manifests/
    sudo vim etcd.yaml
    # Add listen-metrics-urls as etcd command option
    ...
    - --listen-metrics-urls=http://0.0.0.0:2381
    ...
    ```

* Setup `kube-proxy` metrics bind address

    Edit kube-proxy daemon set
    ```bash
    kubectl edit ds kube-proxy -n kube-system
    ...containers:
          - command:
            - /usr/local/bin/kube-proxy
            - --config=/var/lib/kube-proxy/config.conf
            - --hostname-override=$(NODE_NAME)
            - --metrics-bind-address=0.0.0.0  # Add metrics-bind-address line
    ```
    Edit kube-proxy config map
    ```bash
    kubectl -n kube-system edit cm kube-proxy
    ...
        kind: KubeProxyConfiguration
        metricsBindAddress: "0.0.0.0:10249" # Add metrics-bind-address host:port
        mode: ""
    ```
    Delete the kube-proxy pods and reapply the new configuration
    ```bash
    kubectl -n kube-system delete po -l k8s-app=kube-proxy
    ```

## Local development using KinD (Kubernetes in Docker)

Prerequisites

* [Kind](https://kind.sigs.k8s.io/)
* [Docker](https://www.docker.com/)
* [Helm3](https://helm.sh/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

Create KinD cluster
```bash
kind create cluster --config helpers/kind_cluster_config.yaml --image kindest/node:v1.19.1
```

Install K8s m8g stack
* Grafana UI is exposed on port `5000`, see http://localhost:5000
* Prometheus UI is exposed on port `5001`, see http://localhost:5001
* Prometheus Alertmanager UI is exposed on port `5002`, see http://localhost:5002
```bash
helm install monitoring . --dependency-update -f helpers/values-kind.yaml
```

## Node Exporter

Bash script to install Node Exporter v0.18.1 on your Ubuntu host.

```bash
./helpers/node_exporter.sh
```
