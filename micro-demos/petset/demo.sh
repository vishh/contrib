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

run "kubectl config use-context gke_vish-net-meetup_us-central1-f_multi-prod"

run "kubectl delete ns demos"
run "kubectl create -f $(relative ../demo-namespace.yaml)"

desc "Create a petset"
run "cat $(relative petset.yaml)"
run "kubectl --namespace=demos create -f $(relative petset.yaml)"

desc "Pods created will have an ordinal index"
run "kubectl --namespace=demos get po"
run "kubectl --namespace=demos get po"

desc "Two persistent volumes were created automatically"
run "kubectl get pv --namespace=demos"

desc "Print stable hostname from pods"
run "kubectl exec --namespace=demos web-0 -- sh -c 'hostname'"
run "kubectl exec --namespace=demos web-1 -- sh -c 'hostname'"

desc "Hostname and cluster DNS are linked"
run "kubectl run --image busybox --namespace=demos --restart=Never dns-test sleep 1000"
run "kubectl exec --namespace=demos dns-test -- nslookup web-0.nginx"
run "kubectl exec --namespace=demos dns-test -- nslookup web-1.nginx"
run "kubectl delete pods --namespace=demos dns-test"

desc "Delete the pods in the petset"
run "kubectl delete po --namespace=demos -l app=nginx"

desc "Wait for the pods to be running again"
run "kubectl --namespace=demos get po"

desc "Now query the hostname of nginx pods"
run "kubectl exec -it --namespace=demos web-0 -- hostname"
run "kubectl exec -it --namespace=demos web-1 -- hostname"

desc "Discover its peers"
run "kubectl run --image tutum/dnsutils --namespace=demos --restart=Never dns-test -- sleep 1000"
run "kubectl exec --namespace=demos dns-test -- nslookup -type=srv nginx.demos"
run "kubectl delete pods --namespace=demos dns-test"

desc "Deleting the pet set will not delete the pods"
run "kubectl delete  --namespace=demos -f petset.yaml"
run "kubectl --namespace=demos get po"

desc "Delete the pods in the petset"
run "kubectl delete po --namespace=demos -l app=nginx"

desc "Persistent volumes are still around. Delete them"
run "kubectl get pvc -l app=nginx --namespace=demos"
run "kubectl delete pvc -l app=nginx --namespace=demos"

run "kubectl delete ns demos"
