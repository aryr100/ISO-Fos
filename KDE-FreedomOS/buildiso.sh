#!/bin/bash

# Revision: V1.0
# (GNU/General Public License version 3.0)
# Created by eznix (https://sourceforge.net/projects/ezarch/)
# Maintained by Frazer Grant

# ----------------------------------------
# Define Variables
# ----------------------------------------

LCLST="en_GB"
# Format is language_COUNTRY where language is lower case two letter code
# and country is upper case two letter code, separated with an underscore

KEYMP="uk"
# Use lower case two letter country code

KEYMOD="pc105"
# pc105 and pc104 are modern standards, all others need to be researched

MYUSERNM="live"
# use all lowercase letters only

MYUSRPASSWD="live"
# Pick a password of your choice

RTPASSWD="toor"
# Pick a root password

MYHOSTNM="FreedomOS-Live"
# Pick a hostname for the machine

# ----------------------------------------
# Functions
# ----------------------------------------

# Test for root user
#rootuser () {
#  if [[ "$EUID" = 0 ]]; then
#    continue
#  else
#    echo "Please Run As Root"
#    sleep 2
#    exit
#  fi
#}

# Display line error
handlerror () {
clear
set -uo pipefail
trap 's=$?; echo "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR
}

# Clean up working directories
cleanup () {
[[ -d ./FreedomOS ]] && rm -r ./FreedomOS
[[ -d ./work ]] && rm -r ./work
[[ -d ./out ]] && mv ./out ../
#mkdir work
sleep 2
}

# Requirements and preparation
prepreqs () {
pacman -S --noconfirm archlinux-keyring
pacman -S --needed --noconfirm archiso mkinitcpio-archiso
}

# Copy FreedomOS to working directory
cpFreedomOS () {
cp -r /usr/share/archiso/configs/releng/ ./FreedomOS
rm -r ./FreedomOS/efiboot
rm -r ./FreedomOS/syslinux
}

# Copy ezrepo to opt
cpezrepo () {
cp -r ./opt/FreedomOS /opt/
}

# Remove ezrepo from opt
#rmezrepo () {
#rm -r /opt/ezrepo
#}

# Delete automatic login
#nalogin () {
#rm -r ./FreedomOS/airootfs/etc/systemd/system/getty@tty1.service.d
#}

# Remove cloud-init, hyper-v, qemu-guest, vmtoolsd, sshd, & iwd services
rmunitsd () {
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/hv_fcopy_daemon.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/hv_kvp_daemon.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/hv_vss_daemon.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/qemu-guest-agent.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/vmtoolsd.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/vmware-vmblock-fuse.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/sshd.service
rm ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/iwd.service
rm -r ./FreedomOS/airootfs/etc/systemd/system/cloud-init.target.wants
}

# Add Bluetooth, cups, haveged, NetworkManager, & sddm systemd links
addnmlinks () {
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/network-online.target.wants
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/bluetooth.target.wants
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/printer.target.wants
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/sockets.target.wants
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/timers.target.wants
mkdir -p ./FreedomOS/airootfs/etc/systemd/system/sysinit.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager-wait-online.service ./FreedomOS/airootfs/etc/systemd/system/network-online.target.wants/NetworkManager-wait-online.service
ln -sf /usr/lib/systemd/system/NetworkManager-dispatcher.service ./FreedomOS/airootfs/etc/systemd/system/dbus-org.freedesktop.nm-dispatcher.service
ln -sf /usr/lib/systemd/system/NetworkManager.service ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/NetworkManager.service
ln -sf /usr/lib/systemd/system/bluetooth.service ./FreedomOS/airootfs/etc/systemd/system/bluetooth.target.wants/bluetooth.service
ln -sf /usr/lib/systemd/system/haveged.service ./FreedomOS/airootfs/etc/systemd/system/sysinit.target.wants/haveged.service
ln -sf /usr/lib/systemd/system/cups.service ./FreedomOS/airootfs/etc/systemd/system/printer.target.wants/cups.service
ln -sf /usr/lib/systemd/system/cups.socket ./FreedomOS/airootfs/etc/systemd/system/sockets.target.wants/cups.socket
ln -sf /usr/lib/systemd/system/cups.path ./FreedomOS/airootfs/etc/systemd/system/multi-user.target.wants/cups.path
ln -sf /usr/lib/systemd/system/bluetooth.service ./FreedomOS/airootfs/etc/systemd/system/dbus-org.bluez.service
ln -sf /usr/lib/systemd/system/sddm.service ./FreedomOS/airootfs/etc/systemd/system/display-manager.service
}

# Copy files to customize the ISO
cpmyfiles () {
cp packages.x86_64 ./FreedomOS/
cp pacman.conf ./FreedomOS/
cp profiledef.sh ./FreedomOS/
cp -r grub ./FreedomOS/
cp -r efiboot ./FreedomOS/
cp -r syslinux ./FreedomOS/
cp -r usr ./FreedomOS/airootfs/
cp -r etc ./FreedomOS/airootfs/
cp -r opt ./FreedomOS/airootfs/
cp -r boot ./FreedomOS/airootfs/
rm ./FreedomOS/grub/grub.cfg
mv ./FreedomOS/grub/ezgrubcfg ./FreedomOS/grub/grub.cfg
}

# Set hostname
sethostname () {
echo "${MYHOSTNM}" > ./FreedomOS/airootfs/etc/hostname
}

# Create passwd file
crtpasswd () {
echo "root:x:0:0:root:/root:/usr/bin/bash
"${MYUSERNM}":x:1000:1000::/home/"${MYUSERNM}":/bin/bash" > ./FreedomOS/airootfs/etc/passwd
}

# Create group file
crtgroup () {
echo "root:x:0:root
sys:x:3:"${MYUSERNM}"
adm:x:4:"${MYUSERNM}"
wheel:x:10:"${MYUSERNM}"
log:x:19:"${MYUSERNM}"
network:x:90:"${MYUSERNM}"
floppy:x:94:"${MYUSERNM}"
scanner:x:96:"${MYUSERNM}"
power:x:98:"${MYUSERNM}"
uucp:x:910:"${MYUSERNM}"
audio:x:920:"${MYUSERNM}"
lp:x:930:"${MYUSERNM}"
rfkill:x:940:"${MYUSERNM}"
video:x:950:"${MYUSERNM}"
storage:x:960:"${MYUSERNM}"
optical:x:970:"${MYUSERNM}"
sambashare:x:980:"${MYUSERNM}"
users:x:985:"${MYUSERNM}"
"${MYUSERNM}":x:1000:" > ./FreedomOS/airootfs/etc/group
}

# Create shadow file
crtshadow () {
usr_hash=$(openssl passwd -6 "${MYUSRPASSWD}")
root_hash=$(openssl passwd -6 "${RTPASSWD}")
echo "root:"${root_hash}":14871::::::
"${MYUSERNM}":"${usr_hash}":14871::::::" > ./FreedomOS/airootfs/etc/shadow
}

# create gshadow file
crtgshadow () {
echo "root:!*::root
"${MYUSERNM}":!*::" > ./FreedomOS/airootfs/etc/gshadow
}

# Set the keyboard layout
setkeylayout () {
echo "KEYMAP="${KEYMP}"" > ./FreedomOS/airootfs/etc/vconsole.conf
}

# Create 00-keyboard.conf file
crtkeyboard () {
mkdir -p ./FreedomOS/airootfs/etc/X11/xorg.conf.d
echo "Section \"InputClass\"
        Identifier \"system-keyboard\"
        MatchIsKeyboard \"on\"
        Option \"XkbLayout\" \""${KEYMP}"\"
        Option \"XkbModel\" \""${KEYMOD}"\"
EndSection" > ./FreedomOS/airootfs/etc/X11/xorg.conf.d/00-keyboard.conf
}

# Fix 40-locale-gen.hook and create locale.conf
crtlocalec () {
sed -i "s/en_GB/"${LCLST}"/g" ./FreedomOS/airootfs/etc/pacman.d/hooks/40-locale-gen.hook
echo "LANG="${LCLST}".UTF-8" > ./FreedomOS/airootfs/etc/locale.conf
}

# Start mkarchiso
runmkarchiso () {
mkarchiso -v -w ./work -o ./out ./FreedomOS
}



# ----------------------------------------
# Run Functions
# ----------------------------------------

handlerror
prepreqs
cleanup
cpFreedomOS
addnmlinks

rmunitsd
cpmyfiles
sethostname
crtpasswd
crtgroup
crtshadow
crtgshadow
setkeylayout
crtkeyboard
crtlocalec
runmkarchiso


# Disclaimer:
#
# THIS SOFTWARE IS PROVIDED BY EZNIX “AS IS” AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
# EVENT SHALL EZNIX BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
# IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# END
