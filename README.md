
This collection of utility scripts is designed to help anyone using Bitnami appliance VMs in tandem with VirtualBox to get started quickly.

The VMs that these scripts set up connect to a private "sandbox" network that is only visible to the host OS (your workstation) and to its guest VMs.  They are not visible to any other machines on your LAN.  But since each VM can see one another, these scripts help you simulate environments with multiple different servers that communicate with eachother (eg, a MySQL server, a PHP application running on Apache, and a nodejs messaging service).


## Requirements

Before these scripts are useful, you'll first need to download and install VirtualBox from their [downloads page](https://www.virtualbox.org/wiki/Downloads).

You'll also want to set your host OS up with some way to mount "remote" volumes over SSH.  This will allow you to mount directories from a guest OS's filesystem for access from appliations running on your host OS.  This is particularly handy because the Bitnami VMs do not have GUI environments, so mounting directories onto the host OS will permit you to edit files using your favorite text editor.  I recommend using SSHFS as an OSS solution, but there are a variety of commercial apps out there that can handle such mounting operations, including Expandrive, Transmit, Forklift, and others.

If you haven't already downloaded a Bitnami VM that you intend to use, then you should grab one (or more) from [here](http://bitnami.org/stacks).


## Create the VirtualBox VM definition

Once you've got VirtualBox installed and have a Bitnami stack VM downloaded and expanded, figure out the absolute path of the main VM file (*.vmdk) and run the `create-vm.sh` like so:

    $ ./create-vm.sh "My Bitnami VM" /path/to/bitnami/primary-disk-image.vmdk

The script will create and configure your new VM to use a copy of the downloaded Bitnami VM HDD, and have configured your VM's networking so that it can easily be accessed by your host OS.  Once the configured VM is all set up, the script will also launch it immediately.


## Prepare the Guest OS

Once the guest OS has booted, you'll need to login to the Bitnami VM.  The username and password are both `bitnami`, but you'll be prompted to pick a new password.  Once you've logged in and you're looking at the shell, enter the following commands:

    $ curl https://raw.github.com/prometheas/VirtualBox-Bitnami-Utils/master/guest/prepare-vm.sh > prepare-vm.sh
	$ chmod +x prepare-vm.sh
	$ sudo ./prepare-vm.sh

You'll be prompted for some resopnses along the way.  One of the prompts will be for the creation of a new user.  You man elect to create a user whose name matches the one you're using on your Host OS.  This may be easier for you to remember, and can simplify ssh logins by allow implicit username identification.

You'll also be asked for the IP address you want the VM to use.  If you only intend to use a single VM, the default value is fine, but if you are creating multiple VMs, and intend for them to be run simultaneously, be sure to enter unique values.

Whatever you guest OS's IP address, be sure to note it.

If you've missed it, you can always get back at it by typing:

    $ ifconfig eth1

Additionally, when the script is done running, it will advise you to update your `/etc/network/interfaces` file so that the IP address assignment persists after a reboot.  You are strongly recommended to do so.

Now you can minimize this VM's window; it's a pain to use as it doesn't offer the ability to select text in it, or access to the clipboard.  The good news is that one of the things that the script has done is set up sshd on the VM, so you'll be able to access its shell environment from a terminal app running in your host OS.  More on that in a bit.


## Prepare the Host OS

Next you'll want to edit the hosts file in your host OS.  On a UNIX-like OS, this file is typically found at `/etc/hosts`.  Assuming you've used the default IP address of `192.168.56.101`, add the following line to the end of your hosts file:

    192.168.56.101     my-new-bitnami-server.vm

To test that everything works, open your favorite web browser and navigate to http://my-new-bitnami-server.vm.  Naturally, if you've used a different hostname in your hosts file, use that instead.

NOTE: I like to use the tld `.vm` for my VM hostnames, but that's not necessary.  You may use `.local`, `.dev`, `.com`, or none at all.


## SSH Into the Guest OS

Fire up your terminal app of choice and ssh into your new VM.

    $ ssh my-new-bitnami-server.vm

NOTE: This assumes that you had created a user on the VM whose name matches the username you use on your host OS, and that you've also opted to use the hostname from the example above.

Once you've SSHed into the VM, Bob's your uncle.

If you need to edit any files on the guest OS, you can use an SFTP client, or mount whole directories from its filesystem over sshfs (or some such).
