In `inventory/inventory.ini`, the group `installer` holds four test machines:
`installer{9,10}-{bios,uefi}`. Each has a pinned IP in the libvirt network and an entry in `/etc/hosts`.

Their host_vars (`installer9-bios.yml`, ...) are soft-links to the distribution host_vars (`rocky9-bios.yml`, ...). The distribution host_vars use the local mirror in `~/web/mirror` (served at `http://192.168.122.1/`: `rocky/{9,10}`, `rhel/{9.8,10.2}`).
To test another distribution on a machine, re-point its soft-link, for example:

```sh
cd inventory/host_vars/
ln -sf rocky10-uefi.yml installer9-uefi.yml

cd ../..
ansible-playbook -l installer9-uefi playbook.yml
```
