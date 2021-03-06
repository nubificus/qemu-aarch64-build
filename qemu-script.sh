#!/bin/bash

export LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}
export QEMU_AUDIO_DRV=none
export OCL_DEV_TYPE=1

smp=1
cpu=host
ram=256

machine="virt,accel=kvm"
kernel="-kernel Image"
dtb=""
rootfs=rootfs.img

cmdline="rw root=/dev/vda mem=${ram}M"

cd /data

mkdir -p networks
if [[ ! -f networks/.downloaded ]]; then
	/usr/local/share/jetson-inference/tools/download-models.sh
	[[ $? -eq 0 ]] && touch networks/.downloaded
fi

fsck.ext4 -fy $rootfs 1>/dev/null 2>&1

TERM=linux qemu-system-aarch64 \
	-cpu $cpu -m $ram -smp $smp -M $machine -nographic $kernel $dtb -append "$cmdline" 2>stderr.log \
	-drive if=none,id=rootfs,file=$rootfs,format=raw,cache=none -device virtio-blk,drive=rootfs \
	-netdev type=tap,id=net0 -device virtio-net,netdev=net0 \
	-fsdev local,id=fsdev0,path=/data/data,security_model=none \
	-device virtio-9p-pci,fsdev=fsdev0,mount_tag=data \
	-device virtio-rng-pci \
	-object acceldev-backend-generic,id=gen0 \
	-device virtio-accel-pci,id=accel0,generic=gen0
