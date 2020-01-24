#!/bin/bash

. ./multipass-demo-magic.sh

## create 2 worker node kind cluster with a feature gate enabled
p "[*] LET'S GET THIS DEMO STARTED"
p "[.] kind"
pe "kubectl cluster-info"
pe "docker ps"
TYPE_SPEED=100
pe "time (kind create cluster --config ~/multipass-kind-2worker-ephemeral-config.yaml --image kindest/node:v1.16.3 --wait 5m && kubectl wait --timeout=5m --for=condition=Ready nodes --all)"
TYPE_SPEED=20
pe "docker ps"

## view cluster status
pe "kubectl get no -o wide"
pe "kubectl get po -A"

## try to deploy old deployment spec
p "[.] k8s 1.16 api changes"
pe "cat multipass-example-deploy.yaml"
pe "kubectl apply -f multipass-example-deploy.yaml"
pe "kubectl convert -f multipass-example-deploy.yaml | kubectl apply -f -"

## deploy a minimal pod
p "[.] k8s 1.16 ephemeral containers"
pe "cat ~/multipass-example-pod.yaml"
TYPE_SPEED=100
pe "kubectl apply -f ~/multipass-example-pod.yaml && kubectl wait --for=condition=ready --timeout=30s pod/example-pod"

## jump into the pod and see what limited utilities are present
p "[?] will this pod have curl openssl file tcpdump?"
TYPE_SPEED=20
pe "kubectl exec -it example-pod sh"

## inject the ephemeral container
pe "kubectl replace --raw /api/v1/namespaces/default/pods/example-pod/ephemeralcontainers -f ~/multipass-example-debug.json"

## check state of the add'l container
TYPE_SPEED=100
p "[*] watch pod via:  watch kubectl get pods example-pod -o jsonpath='{.status.ephemeralContainerStatuses[0].state}' && echo"
TYPE_SPEED=20
pe "kubectl describe po example-pod"

## once running, attach to pod via add'l container and see debug utils
TYPE_SPEED=100
p "[?] will this pod have curl openssl file tcpdump?"
p "[*] run this in the pod:  tcpdump -i any -c20 -nn -vv"
p "[*] run this in another shell:  kubectl run -i --rm --restart=Never minideb-extras --image=bitnami/minideb-extras -- sh -c \"curl -vvv http://\$(kubectl get po example-pod -o jsonpath='{.status.podIP}')\""
TYPE_SPEED=20
pe "kubectl attach -it example-pod -c debugger"

## notice ephemeral container is gone and can no longer be attached
pe "kubectl describe po example-pod"
pe "kubectl attach -it example-pod -c debugger"

p "[*] DEMO COMPLETE"

## exit multipass shell
#exit
