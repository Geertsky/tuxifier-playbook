In `inventory/inventory.ini`, the group `installer` holds six test machines:
`installer{8,9,10}-{bios,uefi}`. Each has a pinned IP in the libvirt network and an entry in `/etc/hosts`.

Their host_vars (`installer8-bios.yml`, ...) are soft-links to the distribution host_vars (`rocky8-bios.yml`, ...). The distribution host_vars use the local mirror in `~/web/mirror` (served at `http://192.168.122.1/`: `rocky/{8,9,10}`, `rhel/{9.8,10.2}`).
To test another distribution on a machine, re-point its soft-link, for example:

```sh
cd inventory/host_vars/
ln -sf rocky10-uefi.yml installer8-uefi.yml

cd ../..
ansible-playbook -l installer8-uefi playbook.yml
```
