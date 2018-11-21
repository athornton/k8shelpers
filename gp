#!/bin/bash

kubectl get pods | grep ^$1 | grep -v ^NAME | awk '{print$1}'
