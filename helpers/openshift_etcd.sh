#!/bin/bash -e
# Namespace to install dNation k8s monitoring
NS='dnation-monitoring'
# Get ETCD certificate from 'openshift-config' namespace
CA=$(kubectl get cm -n openshift-config etcd-metric-serving-ca -o jsonpath='{.data.ca-bundle\.crt}')
CRT=$(kubectl get secret -n openshift-config etcd-metric-client -o jsonpath='{.data.tls\.crt}' | base64 -d)
KEY=$(kubectl get secret -n openshift-config etcd-metric-client -o jsonpath='{.data.tls\.key}' | base64 -d)
# Create etcd client secret
kubectl create secret generic -n $NS  kube-etcd-client-certs --from-literal=etcd-client.key="$KEY" --from-literal=etcd-client.crt="$CRT" --from-literal=etcd-client-ca.crt="$CA"
# Copy CA bundle configmap from openshift config namespace as is
CM=$(kubectl get configmap  openshift-service-ca.crt --namespace=openshift-config -o jsonpath='{.data.service-ca\.crt}')
kubectl create cm -n $NS  serving-certs-ca-bundle --from-literal=service-ca.crt="$CM"
