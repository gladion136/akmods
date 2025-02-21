#!/bin/sh

set -oeux pipefail

ARCH="$(rpm -E '%_arch')"
KERNEL="$(rpm -q "${KERNEL_NAME}" --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}')"
RELEASE="$(rpm -E '%fedora')"

curl -LsSf -o /etc/yum.repos.d/_copr_gladion136-tuxedo-drivers-kmod.repo "https://copr.fedorainfracloud.org/coprs/gladion136/tuxedo-drivers-kmod/repo/fedora-${RELEASE}/gladion136-tuxedo-drivers-kmod-fedora-${RELEASE}.repo"

### BUILD tuxedo-drivers (succeed or fail-fast with debug output)
dnf install -y \
    "akmod-tuxedo-drivers-*.fc${RELEASE}.${ARCH}" kmod-tuxedo-drivers-*.fc${RELEASE}.${ARCH}

akmods --force --kernels "${KERNEL}" --kmod tuxedo-drivers

for file in /usr/lib/modules/${KERNEL}/extra/tuxedo-drivers/*.ko.xz; do
    modinfo "$file" > /dev/null \
    || (find /var/cache/akmods/tuxedo-drivers/ -name \*.log -print -exec cat {} \; && exit 1)
done

# Check if the RPM package is built and available
RPM_PACKAGE="/var/cache/akmods/tuxedo-drivers/kmod-tuxedo-drivers-${KERNEL}-4.12.1-1.fc${RELEASE}.${ARCH}.rpm"
if [ ! -f "$RPM_PACKAGE" ]; then
    echo "ERROR: $RPM_PACKAGE package is not built or not available"
    exit 1
fi

rm -f /etc/yum.repos.d/_copr_gladion136-tuxedo-drivers-kmod.repo