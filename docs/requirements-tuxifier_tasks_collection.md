# Requirements tuxifier tasks collection
As stated in the [tuxifier architecture](architecture.md) document, the tuxifier tasks collection to fulfill are:
- partitioning of a disk
- creation of file systems
- create an LVM layout (optionally)
- mount file systems
- download software
- install software

In this document I'll research what are the requirements for each of these tasks.
## Partitioning of a disk
For the partitioning of a disk, there are two options followed by their requirements:
1) community.general.parted role
  - parted version 1.8.3 and above.
  - for align option parted version 2.1 and above is required
2) Linux System Roles collection storage role
  - ansible.posix collection
  - kmod-kvdo
  - libblockdev-crypto
  - libblockdev-dm
  - libblockdev-lvm
  - libblockdev-mdraid
  - libblockdev-swap
  - python3-blivet
  - vdo
  - xfsprogs
## Creation of file systems
1) community.general.filesystem
- util-linux
- any Linux native tool for creation of the different filesystems. Some possible examples:
  - bcachefs-tools
  - btrfs-progs
  - dosfstools
  - e2fsprogs
  - f2fs-tools
  - gfs2-utils
  - nilfs-tools
  - ocfs2-tools
  - reiserfsprogs
  - xfsprogs
## support for LVM
1) community.general lvm related roles
  - community.general.lvg
    - devicemapper
    - lvm2
  - community.general.lvol
    - lvm2
  - community.general.lvm_pv
    - lvm2

## mount file systems
1) ansible.posix.mount
  - util-linux
## download software
- curl
## install software
1) preferable dnf
2) minimally rpm
