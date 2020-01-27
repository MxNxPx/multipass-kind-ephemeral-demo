#!/bin/bash

. ./multipass-demo-magic.sh
echo;echo
## create 2 worker node kind cluster with a feature gate enabled
PROMPT_TIMEOUT=0.1
MSG="LET'S GET THIS DEMO STARTED..."
COW="/usr/share/cowsay/cows/default.cow"
pe "echo \$MSG | cowsay -f \$COW"

echo;echo
PROMPT_TIMEOUT=0
p "[.] kind"
PROMPT_TIMEOUT=0.1
pe "kubectl cluster-info"
pe "docker ps"
TYPE_SPEED=300
PROMPT_TIMEOUT=0
pe "time (kind create cluster --config ~/multipass-kind-2worker-ephemeral-config.yaml --image kindest/node:v1.16.3 --wait 5m && kubectl wait --timeout=5m --for=condition=Ready nodes --all)"
TYPE_SPEED=20
PROMPT_TIMEOUT=0.1
pe "docker ps -a --format \"table {{.Names}}\\\t{{.Image}}\\\t{{.Status}}\\\t{{.Labels}}\""

## view cluster status
pe "kubectl get no -o wide"
pe "kubectl get po -A"

## try to deploy old deployment spec
echo;echo
PROMPT_TIMEOUT=0
p "[.] k8s 1.16 api changes"
PROMPT_TIMEOUT=0.1
pe "cat multipass-example-deploy.yaml"
pe "kubectl get deploy,pods"
pe "kubectl apply -f multipass-example-deploy.yaml"
pe "kubectl get deploy,pods"
PROMPT_TIMEOUT=0
pe "kubectl convert -f multipass-example-deploy.yaml | kubectl apply -f -"
PROMPT_TIMEOUT=0.1
pe "kubectl wait --for=condition=available --timeout=30s deploy/nginx"
pe "kubectl get deploy,pods"

## deploy a minimal pod
echo;echo
PROMPT_TIMEOUT=0
p "[.] k8s 1.16 ephemeral containers"
PROMPT_TIMEOUT=0.1
pe "cat ~/multipass-example-pod.yaml"
TYPE_SPEED=300
pe "kubectl apply -f ~/multipass-example-pod.yaml && kubectl wait --for=condition=ready --timeout=30s pod/example-pod"

## jump into the pod and see what limited utilities are present
p "[?] will this pod have what i need to troubleshoot: curl openssl file tcpdump?"
TYPE_SPEED=20
PROMPT_TIMEOUT=0
pe "kubectl exec -it example-pod sh"

## inject the ephemeral container
TYPE_SPEED=300
PROMPT_TIMEOUT=0.1
pe "kubectl replace --raw /api/v1/namespaces/default/pods/example-pod/ephemeralcontainers -f ~/multipass-example-debug.json"

## check state of the add'l container
p "[*] watch pod via:  watch kubectl get pods example-pod -o jsonpath='{.status.ephemeralContainerStatuses[0].state}' && echo"
PROMPT_TIMEOUT=0
TYPE_SPEED=20
pe "kubectl describe po example-pod"

## once running, attach to pod via add'l container and see debug utils
TYPE_SPEED=300
PROMPT_TIMEOUT=0.1
p "[?] will this pod have what i need to troubleshoot: curl openssl file tcpdump?"
p "[*] run in the pod:"
p "[.]   curl localhost"
p "[.]   tcpdump -i any -c20 -nn -vv"
p "[.]   openssl s_client -connect localhost"
p "[*] run this in another shell:"
p "[.]   kubectl run -i --rm --restart=Never minideb-extras --image=bitnami/minideb-extras -- sh -c \"curl -vvv http://\$(kubectl get po example-pod -o jsonpath='{.status.podIP}')\""
TYPE_SPEED=20
PROMPT_TIMEOUT=0
pe "kubectl attach -it example-pod -c debugger"

## notice ephemeral container is gone and can no longer be attached
pe "kubectl describe po example-pod"
pe "kubectl attach -it example-pod -c debugger"

echo;echo
MSG="DEMO COMPLETE!"
COW="/usr/share/cowsay/cows/sheep.cow"
pe "echo \$MSG | cowsay -f \$COW"

## exit multipass shell
#exit
