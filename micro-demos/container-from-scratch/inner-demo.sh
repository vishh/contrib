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

desc "This demo creates a container sandbox using standard linux utilities"
desc "This demo is based on an Ubuntu base image"
run "cat /etc/os-release"

desc "This demo pod is running on a host with a different base image"
run "cat /rootfs/etc/os-release"

desc "Step 1: Create a virtual host or container sandbox using Linux Namespaces"
desc "We will create virtual process trees, ipc and filesystem contexts"
sleep 3
desc "Using 'unshare' linux utility to create a new set of namespaces and use a sleep process to anchor the namespaces"
sleep 2
desc "unshare --net --pid --uts --ipc --mount -f sleep infinity &"
unshare --net --pid --uts --ipc --mount -f sleep infinity &
sleep 2
NSPATH="/proc/`pidof sleep`/ns"

desc "Namespaces are tied to the anchor process"
desc "Current namespaces"
run "ls -l /proc/self/ns/* | awk '{print \$11}'"

desc "The new namespaces"
run "ls -l ${NSPATH}/* | awk '{print \$11}'"

desc "Step 2: Setup Networking"
desc "Use 'CNI' utility to create a veth interface and connect this container to the rest of it's world"
desc "let's look at CNI configuration being used" 
run "cat /etc/cni/net.d/veth-bridge.json"
desc "Notice the bridge name and the Ipam"
desc "Setup networking for the container"
run "./cnitool add bridge-net ${NSPATH}/net"

desc "Network interfaces in my test pod"
run "ifconfig"
desc "Network interfaces in the new container sandbox"
run "nsenter -t `pidof sleep` -n ifconfig"

desc "Step 3: Create the Overlay filesystem"
desc "This demo has a pre-packaged container base image as a tarball"
desc "Create a base directory for the base image"
run "mkdir -p /busybox-base"
desc "Untar the container base image into the directory just created"
run "tar -xvf /busybox.tar -C /busybox-base"

desc "setup directories to create an overlay filesystem"
run "mkdir -p /dev/writable-layer" 
run "mkdir -p /dev/.work"
run "mkdir -p /rootfs"

desc "create an overlay filesystem at /rootfs inside the container virtual host"
run "nsenter -t `pidof sleep` -p -i -u -m -n mount -t overlay -o lowerdir=/busybox-base,upperdir=/dev/writable-layer,workdir=/dev/.work none /rootfs"

desc "Now I have a busybox based linux distro on top of Ubuntu distro that my pod is using"
desc "My pod that's running this demo is itself running on top of some other Linux distro"

run "nsenter -t `pidof sleep` -m touch /rootfs/test-file"
desc "The new file is only on the writable (scratch) layer"
run "ls -l /dev/writable-layer/*"
desc "The new file is not on the busybox base image"
run "find /busybox-base | grep test-file"

desc "Step 4: Create control groups"
run "cgcreate -a `whoami`:`whoami` -t `whoami`:`whoami` -g cpu,memory:test"

desc "Our current control group is"
run "cat /proc/self/cgroup | grep -E \"cpu,|memory:\""

desc "Now lets move the the demo process into the 'test' sub cgroup that was just created"
run "echo $$ > /sys/fs/cgroup/cpu/test/tasks"
run "echo $$ > /sys/fs/cgroup/memory/test/tasks"

desc "Our new control group is"
run "cat /proc/self/cgroup | grep -E \"cpu,|memory:\""
desc "note control group is hierarchical and is not tied to a namespace"

desc ""

desc "We are almost done with the container sandbox"
desc "Step 5: Setup proc filesystem inside the new container sandbox"
run "nsenter -t `pidof sleep` -p -i -u -m -n chroot /rootfs mount -t proc none /proc"
desc "Before entering the sandbox let's observe the current process tree"
run "ps aux"
desc "Step 6: Now explore the new container sandbox"
run "nsenter -t `pidof sleep` -p -i -u -m -n chroot /rootfs /bin/sh"
desc "Exiting the demo"
run "exit"