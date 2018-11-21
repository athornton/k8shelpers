#!/bin/bash
pod=$(kubectl get pods | grep ^$1 | awk '{print$1}')
while : ; do
    kubectl describe pod ${pod}
    kubectl logs -f ${pod}
    sleep 10
done
