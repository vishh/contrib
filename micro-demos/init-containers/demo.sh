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

desc "Run a pod with an init container"
run "cat $(relative nginx-init-containers.yaml)"
run "kubectl --namespace=demos create -f $(relative nginx-init-containers.yaml)"

desc "See what we did"
run "kubectl --namespace=demos describe pod nginx"

desc "Expose nginx via a service"
run "kubectl --namespace=demos expose pod nginx --type=NodePort"

desc "Get service information via minikube"
run "minikube service nginx --namespace=demos"

desc "delete the service"
run "kubectl delete svc nginx --namespace=demos"

desc "delete the pod"
run "kubectl delete pod nginx --namespace=demos"
