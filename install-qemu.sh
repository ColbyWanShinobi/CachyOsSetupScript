#!/usr/bin/env bash

set -e -x

running_kernel="$(uname -r)"
installed_kernel=""
bridge_module="/usr/lib/modules/${running_kernel}/kernel/net/bridge/bridge.ko.zst"

if pacman -Q linux-cachyos >/dev/null 2>&1; then
  installed_kernel="$(pacman -Q linux-cachyos | awk '{print $2}')-cachyos"
fi

if [[ -n "${installed_kernel}" ]] && [[ "${running_kernel}" != "${installed_kernel}" ]]; then
  echo "running kernel does not match installed linux-cachyos package" >&2
  echo "running:   ${running_kernel}" >&2
  echo "installed: ${installed_kernel}" >&2
  echo "Reboot into the installed CachyOS kernel, then re-run this script." >&2
  exit 1
fi

if [[ ! -e "${bridge_module}" ]]; then
  echo "bridge kernel module is missing for the running kernel: ${running_kernel}" >&2
  echo "Installed kernels on disk:" >&2
  ls /usr/lib/modules >&2
  echo "Reboot into the currently installed CachyOS kernel, then re-run this script." >&2
  exit 1
fi

sudo pacman -Syu --needed \
  qemu-full \
  qemu-img \
  libvirt \
  virt-manager \
  dnsmasq \
  iptables \
  dmidecode \
  edk2-ovmf \
  virtiofsd

sudo modprobe bridge
sudo modprobe br_netfilter

sudo systemctl enable --now libvirtd

if ! sudo virsh net-info default >/dev/null 2>&1; then
  echo "libvirt default network is missing" >&2
  exit 1
fi

if ! sudo virsh net-info default | grep -q '^Active:.*yes$'; then
  sudo virsh net-start default
fi

if ! sudo virsh net-info default | grep -q '^Autostart:.*yes$'; then
  sudo virsh net-autostart default
fi

for group in kvm input libvirt; do
  if getent group "${group}" >/dev/null; then
    sudo usermod -aG "${group}" "${USER}"
  fi
done

echo "If group membership was changed, log out and back in before using virt-manager as a regular user."
