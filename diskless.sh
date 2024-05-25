#!/bin/bash

function pause(){
 read -s -n 1 -p "Presione espacio para continuar . . ."
 echo ""
}

if [ "$1" == "Install" ]; then
	clear
	echo "Actualizando Repositorios (Forzado)"
	sudo apt-get update
	echo "Instalando dependencias Basicas necesarias"
	sudo apt-get install  make build-essential liblzma-dev isolinux dnsmasq tgt netplan.io
elif [ "$1" == "FullInstall" ]; then
	clear
	echo "Actualizando Repositorios (Forzado)"
	sudo apt-get update
	echo "Instalando dependencias Completas necesarias"
	sudo apt-get install nano ssh git make build-essential liblzma-dev isolinux dnsmasq tgt net-tools netplan.io
elif [ "$1" == "Links" ]; then
	clear
	echo "Video de Youtube:"
	echo "https://www.youtube.com/watch?v=9Ln1xfZztOs"
	echo ""
	echo "Enlace a guia por el autor:"
	echo "https://textdoc.co/rewsnL01RYlXBAQ9"
	echo ""
	echo "Descarga de VHD de Windows 10 (1804)"
	echo "https://www.ccboot.com/super-image.htm"
	echo ""
	echo "Proyecto GIT ipxe"
	echo "https://github.com/ipxe/ipxe.git"
elif [ "$6" == "" ]; then
	clear
	echo "Modo de Uso:"
	echo ""
	echo 'sudo ./diskless.sh Install'
	echo ""
	echo "o"
	echo ""
	echo 'sudo ./diskless.sh FullInstall'
	echo ""
	echo "o"
	echo ""
	echo './diskless.sh Links'
	echo ""
	echo "o"
	echo ""
	echo "sudo ./diskless.sh [Net Card] [Server IP] [Gateway] [inicio de Rango][Fin de Rango][MAC Address]"
	echo ""
	echo "[Net Card] es la conexion de la Tarjeta de Red (no se admite wifi)."
	echo "[Server IP] la IP del Server"
	echo "[Gateway] la IP de Puerta de Enlace"
	echo "[Inicio de Rango] unas IPs antes de la IP del Server"
	echo "[Fin de Rango] unas IPs despues de la IP del Server"
	echo "[MAC Address] La MAC de la pc que sera Diskless"
	echo ""
	echo ""
	echo "Ejemplo:"
	echo ""
	echo 'sudo ./diskless.sh enp0s25 192.168.1.2 192.168.1.1 192.168.1.80 192.168.1.120 40-b0-76-0a-4b-88'
else
	clear
	echo "Se usara la siguiente configuracion:"
	echo "red:$1"
	echo "IP de la PC Server:$2"
	echo "Gateway:$3"
	echo "Inicio de Rando de IP:$4"
	echo "Fin de Rango de IP:$5"
	echo "MAC ADDRESS de PC a bootear:$6"
	echo ""
	pause
	clear
	echo "Borrando Config YAML..."
	rm -f /etc/netplan/00-installer-config.yaml 
	echo "Creando Netplan Dir..."
	mkdir -pv /etc/netplan
	echo "Creando Netplan"
	echo "network:">>/etc/netplan/00-installer-config.yaml
	echo "  ethernets:">>/etc/netplan/00-installer-config.yaml
	echo "    $1:">>/etc/netplan/00-installer-config.yaml
	echo "      dhcp4: no">>/etc/netplan/00-installer-config.yaml
	echo "      addresses:">>/etc/netplan/00-installer-config.yaml
	echo "        - $2/24">>/etc/netplan/00-installer-config.yaml
	echo "      routes:">>/etc/netplan/00-installer-config.yaml
	echo "        - to: default">>/etc/netplan/00-installer-config.yaml
	echo "          via: $3">>/etc/netplan/00-installer-config.yaml
	echo "      nameservers:">>/etc/netplan/00-installer-config.yaml
	echo "        addresses:">>/etc/netplan/00-installer-config.yaml
	echo "        - 1.1.1.1">>/etc/netplan/00-installer-config.yaml
	echo "        - 8.8.8.8">>/etc/netplan/00-installer-config.yaml
	echo "  version: 2">>/etc/netplan/00-installer-config.yaml
	cat /etc/netplan/00-installer-config.yaml 
	pause
	sudo netplan apply
	echo "Deteniendo Resolved"
	sudo systemctl stop systemd-resolved.service
	sudo systemctl disable systemd-resolved.service
	sudo unlink /etc/resolv.conf
	echo "Borrando Resolv"
	rm -f /etc/resolv.conf
	echo "Creando Resolv"
	echo "nameserver 127.0.0.1">>/etc/resolv.conf
	echo "nameserver 8.8.8.8">>/etc/resolv.conf
	echo "nameserver 1.1.1.1">>/etc/resolv.conf
	cat /etc/resolv.conf 
	pause
	echo "Creando Directorios PXE"
	mkdir -pv /pxeboot/{config,firmware}
	echo "Borrando Boot Config"
	rm -f ipxe/src/bootconfig.ipxe
	echo "Creando Boot Config"
	echo '#!ipxe'>>ipxe/src/bootconfig.ipxe
	echo "dhcp">>ipxe/src/bootconfig.ipxe
	echo "chain tftp://$2/config/boot.ipxe">>ipxe/src/bootconfig.ipxe
	cat /ipxe/src/bootconfig.ipxe
	pause
	echo "Cambiando A Directorio ipxe/src"
	cd ipxe/src
	echo "Compilando...(tardara)"
	make bin/ipxe.pxe bin-x86_64-efi/ipxe.efi EMBED=bootconfig.ipxe
	echo "Copiando archivos iPXE hacia /pxeboot/firmware Directory"
	sudo cp -v bin/ipxe.pxe bin-x86_64-efi/ipxe.efi /pxeboot/firmware/
	cd ..
	cd ..
	echo "Respaldando dnsmasq"
 	sudo mv -v /etc/dnsmasq.conf /etc/dnsmasq.conf.backup
	echo "Creando dnsmasq"
	echo "interface=$1">>/etc/dnsmasq.conf
	echo "bind-interfaces">>/etc/dnsmasq.conf
	echo "domain=netvn.local">>/etc/dnsmasq.conf
	echo "dhcp-range=ens38,$4,$5,255.255.255.0,8h">>/etc/dnsmasq.conf
	echo "dhcp-option=option:router,$3">>/etc/dnsmasq.conf
	echo "dhcp-option=option:dns-server,1.1.1.1">>/etc/dnsmasq.conf
	echo "dhcp-option=option:dns-server,8.8.8.8">>/etc/dnsmasq.conf
	echo "enable-tftp">>/etc/dnsmasq.conf
	echo "tftp-root=/pxeboot">>/etc/dnsmasq.conf
	echo "# boot config for BIOS systems">>/etc/dnsmasq.conf
	echo "dhcp-match=set:bios-x86,option:client-arch,0">>/etc/dnsmasq.conf
	echo "dhcp-boot=tag:bios-x86,firmware/ipxe.pxe">>/etc/dnsmasq.conf
	echo "# boot config for UEFI systems">>/etc/dnsmasq.conf
	echo "dhcp-match=set:efi-x86_64,option:client-arch,7">>/etc/dnsmasq.conf
	echo "dhcp-match=set:efi-x86_64,option:client-arch,9">>/etc/dnsmasq.conf
	echo "dhcp-boot=tag:efi-x86_64,firmware/ipxe.efi">>/etc/dnsmasq.conf
	cat /etc/dnsmasq.conf 
	pause
	echo "Reiniciando dnsmasq..."
	sudo systemctl restart dnsmasq
	echo "Borrando target01.conf"
	sudo rm -f /etc/tgt/conf.d/target01.conf
	echo "Creando target01.conf"
	echo "<target iqn.2022-09.net.vn:pc01>">>/etc/tgt/conf.d/target01.conf
	echo "    backing-store /srv/disks/pc01.img">>/etc/tgt/conf.d/target01.conf
	echo "</target>">>/etc/tgt/conf.d/target01.conf
	cat /etc/tgt/conf.d/target01.conf
	pause
	echo "Creando Directorio de Discos Virtuales"
	sudo mkdir /srv/disks
	echo "Creando Disco Virtual..."
	sudo fallocate -l 20G /srv/disks/pc01.img
	ls /srv/disks -hin
	pause
	echo "Reiniciando TGT"
	sudo systemctl restart tgt
	sudo tgtadm --mode target --op show
	pause
	echo "Borrando boot.ipxe"
	rm -f /pxeboot/config/boot.ipxe
	echo "Creando boot.ipxe"
	echo '#!ipxe'>>/pxeboot/config/boot.ipxe
	echo "set server_ip	$2">>/pxeboot/config/boot.ipxe
	echo 'set boot_url tftp://${server_ip}/config/boot-${net0/mac:hexhyp}.ipxe'>>/pxeboot/config/boot.ipxe
	echo "echo Booting from URL ${boot_url}">>/pxeboot/config/boot.ipxe
	echo "chain ${boot_url}">>/pxeboot/config/boot.ipxe
	cat /pxeboot/config/boot.ipxe
	pause
	echo "Borrando client boot si existe"
	rm -f /pxeboot/config/boot-$6.ipxe
	echo '#!ipxe'>>/pxeboot/config/boot-$6.ipxe
	echo "#Setup networking">>/pxeboot/config/boot-$6.ipxe
	echo "echo Setup Networking">>/pxeboot/config/boot-$6.ipxe
	echo "dhcp">>/pxeboot/config/boot-$6.ipxe
	echo "#Boot from SAN">>/pxeboot/config/boot-$6.ipxe
	echo "echo Boot from SAN">>/pxeboot/config/boot-$6.ipxe
	echo "sanboot iscsi:$2:::1:iqn.2022-09.net.vn:pc01">>/pxeboot/config/boot-$6.ipxe
	echo "boot">>/pxeboot/config/boot-$6.ipxe
	ls -hin /pxeboot/config
	pause
	cat /pxeboot/config/boot-$6.ipxe 
	pause
	echo ""
	echo "Finalizado, pruebe a bootear el equipo cuya MAC Address es $6"
fi
	echo ""
	echo "v 1.17 (Escrito para Ubuntu Server 24.04 con apt)"