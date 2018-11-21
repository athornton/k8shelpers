#!/bin/bash

kubectl get pods | grep ^$1 | awk '{print$1}'
