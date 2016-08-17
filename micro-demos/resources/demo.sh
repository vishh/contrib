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

run "kubectl delete ns demos"
run "kubectl create -f $(relative ../demo-namespace.yaml)"

desc "Start a container with CPU & Memory Limits. Container attempts to use 2 CPUs and 150Mi RAM"
run "kubectl run stress --namespace=demos --image=vish/stress  --limits "cpu=0.5,memory=200Mi" -- -mem-total 150Mi -mem-alloc-size 10Mi -mem-alloc-sleep 1s -cpus 2"
desc "Requests default to limits when not specified"
run "kubectl describe pods --namespace=demos -l run=stress"
desc "Look at container usage. Waiting for metrics to be collected..."
pod=$(kubectl get pods -l run=stress --namespace=demos -o template --template "{{range .items}}{{.metadata.name}}{{end}}")
run "kubectl --namespace=demos top pods $pod"
run "kubectl --namespace=demos top pods $pod"

desc "Delete the container"
run "kubectl delete deployments stress --namespace=demos"

desc "Start a container that uses more memory that specified in limits"
run "kubectl run stress --namespace=demos --image=vish/stress --limits "cpu=0.5,memory=200Mi" -- -mem-total 250Mi -mem-alloc-size 10Mi -mem-alloc-sleep 1s -cpus 2"
desc "Container will be OOM killed soon. Notice the restart count on the pod."
run "kubectl --namespace=demos get pods"
run "kubectl --namespace=demos get pods" # multiple times to ensure that the pod has restarted...
run "kubectl --namespace=demos get pods" # multiple times to ensure that the pod has restarted...
run "kubectl --namespace=demos get pods" # multiple times to ensure that the pod has restarted...
desc "Now that the pod has restarted, let's look at the restart reason"
run "kubectl --namespace=demos describe pods -l run=stress"
desc "Notice that the container was OOM killed"

run "kubectl delete ns demos"