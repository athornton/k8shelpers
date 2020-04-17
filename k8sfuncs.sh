#!/bin/bash

function getCompleted() {
    getTerminatedStatus Completed
}

function reapCompleted() {
    reapStatus Completed
}

function reapStatus() {
    local status=$1
    local l=$(getTerminatedStatus $status)
    local ll=''
    if [ -n "${l}" ]; then
        for ll in ${l}; do
            kubectl delete pod ${ll}
        done
    fi
}

function getTerminatedStatus() {
    local status=$1
    local pods=""
    pods=$(kubectl get pods | grep -v NAME | awk '{print $1}' )
    local l=""
    local p=""
    local k=""
    for p in $pods ; do
        k=$(kubectl get pod -o json $p | \
                jq -r .status.containerStatuses[].state.terminated.reason)
        if [ "$k" == "${status}" ]; then
            if [ -z "${l}" ]; then
                l=${p}
            else
                l="${l} $p "
            fi
        fi
    done
    if [ -n "${l}" ]; then
        printf "${l}"
    fi
}

function mapPods() {
    for i in $(kubectl get pods | grep -v NAME | awk '{print $1}' | sort ); do
        j=$(kubectl describe pod $i | grep -i Node: | awk '{print $2}' )
        echo "${i} => ${j}"
    done
}

function gnsp() {
    kubectl config get-contexts $(kubectl config current-context) | \
        awk '{print $5}' | grep -v NAMESPACE
}

function  gp() {
    kubectl get pods | grep ^$1 | awk '{print $1}'
}

function mp() {
    pod=$(kubectl get pods | grep ^$1 | awk '{print $1}')
    while : ; do
        kubectl describe pod ${pod}
        kubectl logs -f ${pod}
        sleep 10
    done
}

function snsp() {
    kubectl config set-context $(kubectl config current-context) --namespace $1
}

function wp() {
    for p in $(kubectl get pods | grep -v NAME | awk '{print $1}'); do
        d=$(kubectl describe pod $p | grep Node: | awk '{print $2}' |
                cut -d '/' -f 1)
        echo "${p}: ${d}"
    done
}

function zapuser() {
    ns=$(kubectl config get-contexts $(kubectl config current-context) | \
             awk '{print $5}' | grep -v NAMESPACE)
    if [ -z "${ns}" ]; then
        echo 1>&2 "Cannot determine namespace."
        exit 2
    fi
    users=""
    while [ -n "${1}" ]; do
        if [ -z "${users}" ]; then
            users="${1}"
        else
            users="${users} $1"
        fi
        shift
    done

    for u in ${users}; do
        un="${ns}-${u}"
        kubectl delete namespace "${un}"
        kubectl get pv | grep -- ${un} | awk '{print $1}' | \
            xargs kubectl delete pv
    done
}

function changecluster() {
    local cl=$1
    case ${cl} in
        prod|dev|nts)
            ln -sf ${HOME}/.kube/k8s-${cl}-config ${HOME}/.kube/config
            echo "Cluster set to '${cl}'."
            ;;
        *)
            echo 1>&2 "Cluster must be one of 'prod', 'dev', or 'nts'."
            ;;
    esac
}

function dedangle() {
    for i in image builder; do
	docker ${i} prune -f
    done
}

function findhub() {
    kubectl get pods | grep hub | grep 'ContainerCreating\|Running' | \
	awk '{print $1}'
}


function bh() {
    ((kubectl delete pod $(findhub) &) | read l) && mp $(findhub)
}
