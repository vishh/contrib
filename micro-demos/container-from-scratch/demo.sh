#!/bin/bash
# Copyright 2017 The Kubernetes Authors All rights reserved.
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

run "kubectl create -f $(relative ../demo-namespace.yaml)"
run "kubectl delete -f $(relative base-pod.yaml) -n demos"
desc "Setup a test pod"
run "kubectl replace -f $(relative base-pod.yaml) -n demos"
run "kubectl get po -n demos -w"

desc "copy demo script to the pod and run the demo inside the pod"
execCmd="kubectl exec -it -n demos $(kubectl get po -n demos -o name | xargs basename) --"
run "kubectl cp ./inner-demo.sh demos/$(kubectl get po -n demos -o name | xargs basename):/micro-demos/container-demo/inner-demo.sh"
run "$execCmd /micro-demos/container-demo/inner-demo.sh"  

run "kubectl delete ns demos"