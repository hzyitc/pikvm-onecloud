#!/bin/bash

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	# Disable first-login
	rm /root/.not_logged_in_yet

	# Enable watchdog
	sed -E -i 's/^[# ]*RuntimeWatchdogSec=.*$/RuntimeWatchdogSec=8/' /etc/systemd/system.conf

	InstallKvmd
} # Main

InstallKvmd() {

	# TAG=$(curl "https://api.github.com/repos/hzyitc/kvmd-debian/releases/latest" | jq -r .tag_name)
	TAG=debian-v3.85
	VERSION=$(echo "$TAG" | grep -oE '[0-9]+([\.-][0-9]+)+')

	# Donwload the packages
	curl -L -O "https://github.com/hzyitc/kvmd-debian/releases/download/${TAG}/{python3-kvmd_${VERSION}_all.deb,kvmd-platform-v2-hdmiusb-generic_${VERSION}_all.deb}"

	# Install them
	dpkg -i python3-kvmd_${VERSION}_all.deb
	dpkg -i kvmd-platform-v2-hdmiusb-generic_${VERSION}_all.deb
	apt install --fix-broken --yes

	# Prepare MSD storage
	# a. Use a new partition to storage
	#	mkfs.ext4 /dev/sdX
	#	echo "LABEL=PIMSD  /var/lib/kvmd/msd  ext4  defaults,X-kvmd.otgmsd-user=kvmd  0  0" >> /etc/fstab
	#	mount -a
	#	mkdir -p /var/lib/kvmd/msd/{images,meta}
	#	chown kvmd -R /var/lib/kvmd/msd/
	# b. Storage in root partititon
	sed -i -E 's/^([ \t]*)main\(\)$/\1#main()\n\1pass/' /usr/bin/kvmd-helper-otgmsd-remount
	mkdir -p /var/lib/kvmd/msd/{images,meta}
	chown kvmd -R /var/lib/kvmd/msd/

	# Disable nginx to free http and https port
	systemctl disable nginx

	# Enable kvmd services
	systemctl enable kvmd-otg kvmd-nginx kvmd

	# All services will be enable by default in firstrun
	# So we need to mask those we don't need
	systemctl mask nginx
	systemctl mask kvmd-bootconfig
	systemctl mask kvmd-watchdog kvmd-tc358743
	systemctl mask kvmd-janus kvmd-janus-static
	systemctl mask kvmd-vnc kvmd-ipmi
	systemctl mask kvmd-otgnet

	rm python3-kvmd_${VERSION}_all.deb kvmd-platform-v2-hdmiusb-generic_${VERSION}_all.deb

} # InstallKvmd

Main "$@"
