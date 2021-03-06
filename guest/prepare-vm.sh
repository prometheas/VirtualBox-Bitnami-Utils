#!/bin/bash


prepare_network()
{
	# Set IP address of guest OS
	DEFAULT_GUEST_IP="192.168.56.101"
	echo -n "Enter desired IP address of VM ("$DEFAULT_GUEST_IP"): "
	read GUEST_IP

	if [[ $GUEST_IP == "" ]]; then
		GUEST_IP=$DEFAULT_GUEST_IP
	fi

	# validate IP addy
	if [[ ! $GUEST_IP =~ ([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})\.[0-9]{1,3} ]]; then
		echo "ERROR: invalid IP address '"$GUEST_IP"'"
		exit;
	else
		# determine network ID from IP addy
		NETWORK_ID=${BASH_REMATCH[ 1 ]}
	fi

	# Pick network interface for inbound connections
	DEFAULT_INTERFACE="eth1"
	echo -n "Enter network interface for inbound connections ("$DEFAULT_INTERFACE"): "
	read INTERFACE

	if [[ $INTERFACE == "" ]]; then
		INTERFACE=$DEFAULT_INTERFACE
	fi

	# validate interface
	INTERFACE_INFO=`ifconfig $INTERFACE 2>/dev/null`
	if [[ $INTERFACE_INFO == "" ]]; then
		echo ERROR: $INTERFACE is an invalid interface
		exit
	fi

	# set the IP address of the chosen interface
	echo
	echo ifconfig $INTERFACE $GUEST_IP netmask 255.255.255.0 up
	ifconfig $INTERFACE $GUEST_IP netmask 255.255.255.0 up

	INTERFACES_FILE=/etc/network/interfaces
	ETH1_DECLARATION=`grep 'iface eth1' $INTERFACES_FILE`
	if [[ $ETH1_DECLARATION == "" ]]; then
		echo ""
		echo "***********************************************************"
		echo "*" Adding network interface to /etc/network/interfaces file:
		echo "***********************************************************"
		echo "" >> $INTERFACES_FILE
		echo "#" The host-only network interface >> $INTERFACES_FILE
		echo auto eth1 >> $INTERFACES_FILE
		echo iface eth1 inet static >> $INTERFACES_FILE
		echo address $GUEST_IP >> $INTERFACES_FILE
		echo netmask 255.255.255.0 >> $INTERFACES_FILE
		echo network $NETWORK_ID.0 >> $INTERFACES_FILE
		echo broadcast $NETWORK_ID.255 >> $INTERFACES_FILE
		echo >> $INTERFACES_FILE
	fi
}


prepare_ssh()
{
	# ensure we have a valid ssh.conf
	if [ ! -e "/etc/init/ssh.conf" ]
	then
		cp /etc/init/ssh.conf.back /etc/init/ssh.conf
	fi

	start ssh
}


update_packages()
{
	yes | apt-get update
	yes | apt-get upgrade
}


prepare_sshfs()
{
	echo Preparing sshfs...
	yes | apt-get install sshfs
	start sshfs
	echo "You may now mount directories in this VM onto your host OS using sshfs!"
}

install_tools()
{
	echo Installing Subversion **************************************
	yes | apt-get install subversion curl
}


prepare_user()
{
	echo
	echo -n "Would you like to create your own user? [Y/n]: "
	read answer

	if [[ $answer == "" ]]; then
		answer="y"
	fi
	
	if [[ $answer == "y" || $answer == "Y" ]]; then
		# retain all groups for bitnami user except group of own username
		BITNAMI_USER_GROUPS=`groups bitnami`
		NEW_USER_GROUPS=${BITNAMI_USER_GROUPS//bitnami : bitnami /}
		NEW_USER_GROUPS=${NEW_USER_GROUPS// /,}
		#NEW_USER_GROUPS=${NEW_USER_GROUPS//,\:/}

		echo -n "Enter new user name (consider matching your login for the host OS): "
		read USERNAME
		
		if [[ ! $USERNAME == "" ]]; then
			adduser $USERNAME
			usermod -a -G $NEW_USER_GROUPS $USERNAME
		fi
	fi
}


update_packages
prepare_ssh
prepare_sshfs
prepare_user
prepare_network
