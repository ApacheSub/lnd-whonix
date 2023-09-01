# lnd-whonix
Setup detailing required configuration for running LND in Whonix

## Setting up Whonix

This guide mainly focuses on running Whonix in KVM. If you use VirtualBox, that is likely fine but some things may not work.

There's some excellent guidance on Whonix for KVM at: https://www.whonix.org/wiki/KVM

I will be covering things that are relevant to the setup.

The setup will consist of 3 Virtual Machines:

- Whonix Gateway
- Bitcoin Daemon
- LND

I recommend following the Whonix for KVM guide so that you have imported Whonix-Gateway and Whonix-Workstation to libvirt. This way you can easily clone them to make new VMs.

### Network setup

First thing you need to do is create a new internal network for all your LND-related VMs.

For that you have to modify the XML file you used to create Whonix-Internal network:

```
<network>
  <name>Whonix-Internal-Bitcoin</name>
  <bridge name='virbr3' stp='on' delay='0'/>
</network>
```

Save it as `Whonix-Internal-Bitcoin.xml` and run:
```
virsh -c qemu:///system net-define Whonix-Internal-Bitcoin.xml
```
```
virsh -c qemu:///system net-autostart Whonix-Internal-Bitcoin.xml
```
```
virsh -c qemu:///system net-start Whonix-Internal-Bitcoin.xml
```

Now we can start working on the Virtual Machines. I assume at this point you have default Whonix-Workstation and Whonix-Gateway imported.

I use virt-manager so what I do is clone 

Whonix-Gateway -> Whonix-Gateway-Bitcoin

Whonix-Workstation -> Whonix-Workstation-Bitcoind

Whonix-Workstation -> Whonix-Workstation-LND

This can be done by right-clicking them in virt-manager.

After cloning we need to change the VMs to use the newly created Whonix-Internal-Bitcoin network.

Double click the VMs in virt-manager and click the light bulb button to change settings. There you should find a tab that starts with NIC. In Network source select Whonix-Internal-Bitcoin.

Alternatively, you can modify the XML by finding `<source network="Whonix-Internal"/>` and changing that.

### Configuring VMs

At this point you can start Whonix-Gateway-Bitcoin and set it up. Remember to change default password, update the system. The gateway should prompt some setup steps when it first runs.

Do the same later for the workstations too but not yet. You can also allocate more resources to each VM than what is the default.

Before starting Whonix-Workstation-Bitcoind and LND, you need to change their default IP addresses.

First, start Whonix-Workstation-LND. At this point you can change the default user password there too.

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

Let's say you have the two `.yml` files in `/home/user/onion-grater/`

```cd /usr/local/etc/onion-grater-merger.d/```
```sudo ln -s /home/user/onion-grater/40_bitcoind.yml 40_bitcoind.yml```
```sudo ln -s /home/user/onion-grater/40_lnd.yml 40_lnd.yml```
```sudo service onion-grater restart```

That's it, now the Gateway will allow what we need.

#### Configuring Bitcoind Workstation

Start the Bitcoind Workstation. Now is the time to change the default password for user if you have not done so yet `sudo passwd user`.

I like to run bitcoind on a non-privileged user. Create an user called bitcoin:

```sudo useradd bitcoin```

Follow the instructions and give the user a password.

We need to enable connections from LND to bitcoind by relaxing some firewall rules:
```sudo -e /etc/whonix_firewall.d/50_user.conf```

Add the following contents:

```EXTERNAL_OPEN_PORTS+=" 8332 8333 8334 28332 28333 "```

Refresh the firewall:

```sudo whonix_firewall```

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

Again, let's open some ports in the firewall in `/etc/whonix_firewall.d/50_user.conf`

```EXTERNAL_OPEN_PORTS+=" 9735 9911 "```

These rules allow LND onion services (including watchtower).

Once again, I like to run LND on a separate user.

```sudo useradd lightning```

I will include a sample `lnd.conf` config that you can use. Some specific Whonix-related stuff included.

Now you're more or less ready to running LND. Run the binary as lightning user. I have linked a couple of resources below to help running LND if needed.

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
