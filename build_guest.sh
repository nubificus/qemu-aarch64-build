#!/bin/bash

cd guest

DOCKER_BUILDKIT=1 docker build --network=host -f Dockerfile.guest.aarch64 -t nubificus/vaccel-qemu-guest --build-arg "TOKEN=$TOKEN" --target artifacts --output type=local,dest=./qemu-guest-aarch64 .

cd qemu-guest-aarch64 && bash create_rootfs.sh rootfs/* && rm -rf rootfs
