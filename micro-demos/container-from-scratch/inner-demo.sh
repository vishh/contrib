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

export DEMO_RUN_FAST=true
run "mkdir -p /busybox-base "
run "tar -xvf /busybox.tar -C /busybox-base"

desc "setup directories to create an overlay filesystem"
run "mkdir -p /dev/writable-layer" 
run "mkdir -p /dev/.work"
run "mkdir -p /rootfs"

desc "create an overlay filesystem"
run "mount -t overlay -o lowerdir=/busybox-base,upperdir=/dev/writable-layer,workdir=/dev/.work none /rootfs"
run "touch /rootfs/file"
run "ls -l /dev/writable-layer/*"

desc "let's add a control group"
run "cgcreate -a `whoami`:`whoami` -t `whoami`:`whoami` -g cpu,memory:`whoami`"

desc "Take a look at your current control groups"
run "cat /proc/self/cgroup | grep -E \"cpu|memory\""

desc "execute a shell within the newly created control groups"
run "cgexec -g cpu,memory:`whoami` /bin/sh -c 'cat /proc/self/cgroup | grep -E \"cpu|memory\" && exit'"

desc "Extend the sandboxes to use linux namespaces"
run "ps aux"

run "unshare --pid --uts --ipc --mount -f chroot /rootfs /bin/sh -c 'mount -t proc proc /proc && ps aux'"


