# Build & run a vAccel-enabled QEMU guest

This repo contains the Dockerfiles & scripts to produce a vAccel-enabled QEMU guest kernel & rootfs.

### building guest kernel & rootfs

To generate the necessary binaries and directories to run a QEMU guest, use:

```
bash build_guest.sh
```

### building container

To build the container with vAccel runtime library & QEMU binaries, use:
```
bash build.sh
```

\*you will have to export the TOKEN variable to be able to pull private repos.

### example usage (VirtIO accel plugin)

To execute the vAccel QEMU guest, use:

```
bash run.sh
```

You can then run an image classification example with:
```
classify <image_path> <iterations>
```

### example usage (VirtIO vSock plugin)

By default our custom VirtIO plugin is used for host-guest communication. To use the VirtIO vSock-based plugin you can run the above script with:

```
bash run.sh -v <cid>
```
where `<cid>` will be the guest identifier for the vSocket (must be >=3).

You will then need to change the transport backend in the guest with:
 
```
export VACCEL_BACKENDS="libvaccel-vsock.so"
```

You can then run an image classification example as above with:
```
classify <image_path> <iterations>
```

You may use the `guest/qemu-guest-{arch}/data` directory (created by the `build_guest.sh` script) to share data between the host and the guest at runtime. The directory is mounted at `/root/data` (via 9p) inside the QEMU guest.

Please note you have to setup nvidia-docker beforehand, in order to use the GPU from the container. Further instructions are provided here: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker
