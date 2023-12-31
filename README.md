# lnd-whonix
Setup detailing required configuration for running LND in Whonix

## Donations are welcome

Bitcoin address: :`bc1qcxgdr6tvnm0wuyejs98pennpyv9ktcz6sxfcca`

## Setting up Whonix

This guide mainly focuses on running Whonix in KVM. If you use VirtualBox, that is likely fine but some things may not work.

I will be covering things that are relevant to the setup.

The setup will consist of 3 Virtual Machines:

- Whonix Gateway
- Bitcoin Daemon
- LND

### Initial steps

Install KVM on your machine and download Whonix

Follow steps here to do it: https://www.whonix.org/wiki/KVM

After you've downloaded the Whonix KVM archive, extract it:

```
tar -Jxvf Whonix*.xz
```

### Network setup

First thing you need to do is create a new internal network for all your LND-related VMs.

#### On the host

Go into the folder where you extracted Whonix previously. There we need to make some modifications on the XML files.

Let's start off by creating an XML file specifying the internal network that we will be using for our VMs.

Run the following command to do so:

```
sed -e 's/virbr2/virbr3/' -e 's/Whonix-Internal/Whonix-Internal-Bitcoin/' Whonix_internal_network-*.xml > Whonix-Internal-Bitcoin.xml
```

Then, let's change the definitions of the VMs to use the new internal network:

```
sed -e 's/Whonix-Internal/Whonix-Internal-Bitcoin/' -e 's/<name>Whonix-Workstation<\/name>/<name>Whonix-Workstation-Template<\/name>/' Whonix-Workstation*.xml > Whonix-Workstation-Template.xml
```

```
sed -e 's/Whonix-Internal/Whonix-Internal-Bitcoin/' -e 's/<name>Whonix-Gateway<\/name>/<name>Whonix-Gateway-Template<\/name>/' Whonix-Gateway*.xml > Whonix-Gateway-Template.xml
```

Now let's ensure networking is enabled:

```
sudo virsh -c qemu:///system net-autostart default
```

```
sudo virsh -c qemu:///system net-start default
```

Next, let's import our networks to libvirt:

```
sudo virsh -c qemu:///system net-define Whonix_external_network*.xml
```

```
sudo virsh -c qemu:///system net-define Whonix-Internal-Bitcoin.xml
```

```
sudo virsh -c qemu:///system net-autostart Whonix-Internal-Bitcoin
```

```
sudo virsh -c qemu:///system net-start Whonix-Internal-Bitcoin
```

```
sudo virsh -c qemu:///system net-autostart Whonix-External
```

```
sudo virsh -c qemu:///system net-start Whonix-External
```

Finally we can import the VMs:

```
sudo virsh -c qemu:///system define Whonix-Gateway-Template.xml
```

```
sudo virsh -c qemu:///system define Whonix-Workstation-Template.xml
```

Now we need to move the `qcow2` images to the folder they belong in. The default location is '/var/lib/libvirt/images/' but depending on if you want them elsewhere, the location may vary.

```
sudo mv Whonix-Gateway*.qcow2 /var/lib/libvirt/images/Whonix-Gateway.qcow2
```

```
sudo mv Whonix-Workstation*.qcow2 /var/lib/libvirt/images/Whonix-Workstation.qcow2
```

Be careful. If you use a non-default location for the images, the changes need to be reflected in the XML files that define the VMs. The location can be changed afterwards and is very easy in virt-manager.

The last thing we need to do is clone the VMs that we are going to configure:

```
sudo virt-clone --original Whonix-Gateway-Template --name Whonix-Gateway-Bitcoin --auto-clone
```

```
sudo virt-clone --original Whonix-Workstation-Template --name Whonix-Workstation-Bitcoind --auto-clone
```

```
sudo virt-clone --original Whonix-Workstation-Template --name Whonix-Workstation-LND --auto-clone
```

### Configuring VMs

At this point you can start Whonix-Gateway-Bitcoin and set it up. Remember to change default password, update the system. The gateway should prompt some setup steps when it first runs.

Do the same later for the workstations too but not yet. You can also allocate more resources to each VM than what is the default.

Before starting Whonix-Workstation-Bitcoind and LND, you need to change their default IP addresses.

First, start Whonix-Workstation-LND. At this point you can change the default user password there too.

#### In Whonix-Workstation-LND

Next edit `/etc/network/interfaces.d/30_non-qubes-whonix` I prefer `sudo -e /path/to/file`.

Find the line under `iface eth0 inet static` where it says `address 10.152.152.11`. Change it to `address 10.152.152.12`.

If this wasn't done, both workstations would have same internal IP address. We don't want that.

Now restart the VM and after that you can also start Whonix-Workstation-Bitcoin.

I like to also disable the graphical environment. This can be done by adding `rads_start_display_manager=0` to `/etc/rads.d/50_user.conf`.

However, you may want to wait before doing this because it severely limits your ability to do things like copy pasting etc.

#### Configuring the Gateway

There is not much configuration to do but we need enable adding and removing onion services from the two Workstations.

Whonix-Gateway is restrictive as to what Tor Control commands are supported. We need to specifically whitelist what we want to do by an onion-grater profile.

Onion-grater is a proxy between Workstations and the Tor running on the Gateway.

I will include two profiles in this repository:
`40_bitcoind.yml` and `40_lnd.yml`. I have made pull requests about these to the Whonix onion-grater repository. Whonix already has the bitcoind profile shipped by default but I made small modifications of my own to it.

Installing onion-grater profiles:

Let's say you have the two `YAML` files in `/home/user/onion-grater/`

#### In Whonix-Gateway-Bitcoin

```
cd /usr/local/etc/onion-grater-merger.d/
```

```
sudo ln -s /home/user/onion-grater/40_bitcoind.yml 40_bitcoind.yml
```

```
sudo ln -s /home/user/onion-grater/40_lnd.yml 40_lnd.yml
```

```
sudo service onion-grater restart
```

That's it, now the Gateway will allow what we need.

#### Configuring Bitcoind Workstation

Start the Bitcoind Workstation. Now is the time to change the default password for user if you have not done so yet `sudo passwd user`.

I like to run bitcoind on a non-privileged user. Create an user called bitcoin:

#### In Whonix-Workstation-Bitcoind

```
sudo useradd bitcoin
```

Follow the instructions and give the user a password.

We need to enable connections from LND to bitcoind by relaxing some firewall rules:

```
sudo -e /etc/whonix_firewall.d/50_user.conf
```

Add the following contents:

```
EXTERNAL_OPEN_PORTS+=" 8332 8333 8334 28332 28333 "
```

Refresh the firewall:

```
sudo whonix_firewall
```

This does not change the fact that the VMs run in an isolated network. What opening those ports enables is 1) LND to connect to bitcoind and 2) Bitcoind onion-service to function

At this point you can install bitcoind on the machine. I install it for all accounts on the user account and then run bitcoind on the bitcoin user.

I will include a sample `bitcoin.conf` in the repository that you can use. There's some Whonix-specific configurations that need to be done.

You will also need to make rpc credentials with the `rpcauth.py` script which is included with bitcoin core in `bitcoin-XX.0/share/rpcauth`.

At this point it needs to be noted that the `qcow2` volume only has up to 100GB storage space. It's obviously not enough to fit the blockchain.

What I've done is create a new volume with enough space. Go to Bitcoind Workstation settings in virt-manager and at the bottom click Add Hardware. There you can add storage. Make a volume with atleast 650-800 GB as your node can't be pruned.

I have mounted my volume at `/mnt/data/`. Create a folder `.bitcoin` there. Make sure bitcoin user has read/write access. (`sudo chown bitcoin:bitcoin /mnt/data`)

Then go to home (of bitcoin user, as bitcoin user) folder and `ln -s /mnt/data/.bitcoin .bitcoin`. Before running bitcoind, make sure your configuration is in `.bitcoin`.

Now you should be more or less ready to run bitcoind. I have setup bitcoind to run after reboot with crontab but you may do it however you wish. Even manually starting after each reboot works.

#### Configuring LND Workstation

I have included some convenience scripts to the LND folder to initialize the VM and also for downloading LND.

Here are all the steps that you can do manually (the script does not automate everything anyway):

Again, let's open some ports in the firewall in `/etc/whonix_firewall.d/50_user.conf`

```
EXTERNAL_OPEN_PORTS+=" 9735 9911 "
```

These rules allow LND onion services (including watchtower).

Once again, I like to run LND on a separate user.

```
sudo useradd lightning
```

I will include a sample `lnd.conf` config that you can use. Some specific Whonix-related stuff included.

Now you're more or less ready to running LND. Run the binary as lightning user. I have linked a couple of resources below to help running LND if needed.

Following command may be helpful installing LND:

```
sudo install -g root -m 0755 -o root -t /usr/local/bin ln*
```


Now that LND runs in a VM, not to mention Whonix, backups may be a bit trickier. One option is to mount an additional `qcow2` volume on a separate drive where you back up the channels.

I have a script running as lightning user:

```
while true; do
  inotifywait /home/lightning/.lnd/data/chain/bitcoin/mainnet/channel.backup
  cp /home/lightning/.lnd/data/chain/bitcoin/mainnet/channel.backup /mnt/backups/channel.backup
done
```

I also backup to cloud with a similar script.

These two resources helped me a lot setting up LND:
https://blog.lopp.net/tor-only-bitcoin-lightning-guide/
https://github.com/alexbosworth/run-lnd
