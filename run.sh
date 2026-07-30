#! /bin/sh

set -exu
#nix build .\#packages.liveCD.x86_64-linux
#ISO=./result/iso/*.iso
#echo $ISO
#
#qemu-system-x86_64 \
#    -m 4G \
#    -machine pc,accel=kvm,memory-backend=mem,usb=off \
#    -device virtio-scsi-pci,id=scsi0 \
#    -D qemu.log \
#    -object memory-backend-file,id=mem,size=4G,mem-path=/dev/shm,share=on \
#    -audio driver=pa,model=hda,server=/run/user/1000/pulse/native \
#    -device virtio-vga-rutabaga,gfxstream-vulkan=on,cross-domain=on,hostmem=8G \
#    -cdrom $ISO


nix build .\#packages.vm.x86_64-linux
./result/bin/run-nixos-vm \
    -m 4G \
    -object memory-backend-file,id=mem,size=4G,mem-path=/dev/shm,share=on \
    -audio driver=pa,model=hda,server=/run/user/1000/pulse/native
#\
#    -device virtio-vga-rutabaga,gfxstream-vulkan=on,cross-domain=on,hostmem=8G
