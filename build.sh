#!/bin/bash

DOCKER_BUILDKIT=0 docker build --network=host -t nubificus/vaccel-qemu:aarch64 \
	--build-arg "TOKEN=$TOKEN" .
