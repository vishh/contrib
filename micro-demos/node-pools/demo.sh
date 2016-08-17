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

desc "Create a multi-zone cluster"
run "gcloud container clusters create multi-prod --zone us-central1-f --additional-zones=us-central1-a,us-central1-b"

desc "Create a new node pool with larger machines"
run "gcloud container node-pools create high-mem --zone us-central1-f --cluster=multi-prod --machine-type=custom-2-12288 --disk-size=200 --num-nodes=1"

desc "List node pools"
run "gcloud container node-pools list --cluster=multi-prod --zone us-central1-f"

desc "Get nodes in the cluster"
run "kubectl get nodes"

desc "Get a list of failure domain labels from nodes"
run "kubectl get nodes -o yaml | grep zone"
run "kubectl get nodes -o yaml | grep region"

desc "delete the newly added node pool"
run "gcloud container node-pools delete high-mem --cluster=multi-prod --zone us-central1-f"

desc "delete the cluster"
run "gcloud container clusters delete multi-prod --zone us-central1-f"