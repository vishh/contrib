#!/bin/bash
# Copyright 2016 The Kubernetes Authors All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

. $(dirname ${BASH_SOURCE})/../util.sh

run "kubectl config use-context vish-net-meetup_kubernetes"

run "kubectl delete ns demos"
run "kubectl create -f $(relative ../demo-namespace.yaml)"

desc "Open up dashboard"
desc "http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/workload?namespace=demos"

desc "Create a best effort pod"
run "kubectl run --namespace=demos stress-besteffort --image=vish/stress  -- -mem-total 5Gi -mem-alloc-size 500Mi -mem-alloc-sleep 30s -cpus 2"

desc "Create a Guaranteed Pod"
run "kubectl run --namespace=demos stress-guaranteed --image=vish/stress  --limits "cpu=200m,memory=2Gi" -- -mem-total 1990Mi -mem-alloc-size 500Mi -mem-alloc-sleep 10s -cpus 2"

desc "Create a Burstable pod"
run "kubectl run --namespace=demos stress-burstable --image=vish/stress  --requests "cpu=200m,memory=2Gi" -- -mem-total 4Gi -mem-alloc-size 1Gi -mem-alloc-sleep 10s -cpus 2"

desc "Check the state of the nodes"
run "kubectl describe nodes"

desc "Wait & check the state of the nodes again. Notice memory pressure"
run "kubectl describe nodes"
run "kubectl describe nodes"
run "kubectl describe nodes"

desc "Burstable pod should be evicted"
run "kubectl get pods -a --namespace=demos"

desc "Burstable pod will not be pending due to memory pressure"
run "kubectl describe pods --namespace=demos $(kubectl get pods --namespace=demos | grep Pending | awk '{print $1}')"

desc "Delete all the pods"
run "kubectl delete ns demos"
