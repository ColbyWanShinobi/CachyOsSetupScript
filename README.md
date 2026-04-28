# CachyOsSetupScript

`install-localsend.sh` configures the LocalSend discovery and transfer port (`53317` TCP/UDP). The firewall setup is idempotent, so rerunning the script will not add duplicate `ufw` rules.

If LocalSend still cannot discover other devices, check that:
- Both devices are on the same subnet/VLAN.
- AP isolation or guest-mode client isolation is disabled on the router.
- The firewall on the other device also allows LocalSend traffic on `53317` TCP/UDP.

sudo usermod -aG docker ${USER}
newgrp docker

sudo usermod -aG vboxusers ${USER}
newgrp vboxusers
