#!/bin/bash



display_usage()
{
	echo Platform WordPress VM Creation Utility
	echo "(C) 2012 Viacom Media Networks"
	echo All rights reserved.
	echo
	echo Usage:
    echo
	echo "  create-vm <vm_name> <hdd_file_path>"
	echo
	exit;
}

create_virtual_machine()
{
	echo Creating VM \"$VM_NAME\"
	VBoxManage createvm --name "$VM_NAME" --ostype Ubuntu --register

  #configure host-only networks
  HOSTONLY_NETWORKS=$(VBoxManage list hostonlyifs | grep 'vboxnet0' | cut -d '"' -f2)
  if [[ $HOSTONLY_NETWORKS == "" ]]; then
    echo "No host-only networks found.  Creating one... "
    VBoxManage hostonlyif create
  else
    echo "Using existing host-only network 'vboxnet0' for VM"
  fi
	VBoxManage modifyvm "$VM_NAME" --nic2 hostonly --hostonlyadapter2 vboxnet0 --memory 1024

	# get some filesystem information about our newly-created VM
	VM_CONFIG_FILE=$(VBoxManage showvminfo "$VM_NAME" --details --machinereadable | grep 'CfgFile=' | cut -d '"' -f2)
	VM_DIRECTORY=`dirname "$VM_CONFIG_FILE"`

  echo
	echo "This VM will not have a CD drive.  You may add one using the VirtualBox application."
  echo

	echo -n "Copying the Bitnami VM disk images into the created VM directory... "
	eval cp "\"$BITNAMI_DIRECTORY\"/*.vmdk" \"$VM_DIRECTORY\"
	echo DONE!
	
	echo -n Registering Bitnami disk image "\"$VM_DIRECTORY/\"$BITNAMI_FILENAME" with the VM... 
	VBoxManage storagectl "$VM_NAME" --name SATA --add sata --sataportcount 1 --controller IntelAhci --bootable on
	eval VBoxManage storageattach \"$VM_NAME\" --storagectl SATA --type hdd --medium "\"$VM_DIRECTORY/\"$BITNAMI_FILENAME" --port 0 --device 0 --mtype normal
	echo DONE!
}



# collect arguments
VM_NAME=$1
HDD_PATH="$2"

# ensure we have required args
if [[ $VM_NAME == "" || $HDD_PATH == "" ]]; then
	display_usage
fi

# verify the VM name isn't already in use
if [[ ! $(VBoxManage showvminfo "$VM_NAME" --machinereadable 2>/dev/null) == "" ]]; then
	echo \"$VM_NAME\" is already in use by another VM
	exit
fi

HDD_PATH=${HDD_PATH//\~/$HOME}
# validate hard drive image path
if [[ ! -f $HDD_PATH ]]; then
	echo "ERROR: '$HDD_PATH' does not exist.  Please supply a valid disk image."
	exit
fi

BITNAMI_DIRECTORY=`dirname "$HDD_PATH"`
BITNAMI_FILENAME=`basename "$HDD_PATH"`



# all requirements in place; let's get started with the VM creation
create_virtual_machine

echo -n Starting VM... 
VBoxManage startvm "$VM_NAME"
echo DONE!
