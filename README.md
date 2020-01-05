# Raspi Firewall Tester

## Introduction

Ever have an app installed on your work computer behind a corporate firewall, which you had trouble identifying the ports and destination addresses that needed to be whitelisted in order for the app to run properly? Have you try testing a new app at work but ended up getting unexpected behaviors and have ruled out the computers being the cause, insisting that the network could be the culprit?

This appliance tool would be extremely useful in those situations where the security team may need concrete evidence of which ports and destination addresses need to be open as it may be unclear to them which ports they can allow. The app's documentation may not be clear on which exceptions should be made on the firewall or the reference documentation isn't up to date. This is also useful in black box testing when working with unfamiliar apps. 

**BONUS!** You can safely test this in isolation on your home network without bringing down the network for everyone and leaving your computer's OS firewall untouched.

The Raspberry Pi can act as a NAT router, commonly found in most homes, but without the extra fluff. In this case, the NAT network would be configured to `DROP` outgoing packets by default, meaning a global blacklist has been established, and individual exceptions would have to be made. This is typically how corporate firewall operates in strict networking environment.

## Requirements

For Raspberry Pi:

- Raspberry Pi (tested on RPi1 Model B Rev 2 and RPi4 Model B)
- Ethernet cable
- RPi Operating System: [Raspian](https://www.raspberrypi.org/downloads/raspbian/) (latest Lite version recommended - tested on Buster 10.1)
- **Optional:** Compatible WiFi dongle (for older RPi without WiFi built-in)

    **NOTE:** It's recommended to use WiFi dongle that works out of the box without tweaking or compilation such as [CanaKit](https://www.canakit.com/raspberry-pi-wifi.html).

For controlling machine (running SSH client and Ansible):

- Run macOS or Linux on controller machine (required as the instruction isn't for Windows)
- [Python 3](https://www.python.org/downloads/) (tested on 3.7) is installed on controller machine
- [Homebrew](https://brew.sh/) (recommended package manager for macOS only)
- [SSHPass](https://gist.github.com/arunoda/7790979) (for interactive login with SSH... *shhhhhh, yes this is intentional!* )
- Nmap (can be obtained through a package manager)

## Before We Begin

We need to set up the Raspberry Pi first. I prefer running the Raspberry Pi in headless (no GUI) operation as it's quicker and convenient. With that being said, the Raspian Lite image was my clear go-to choice. The Raspberry Pi Foundation has developed an installation tutorial for most beginners which can be found [here](https://www.raspberrypi.org/documentation/installation/installing-images/README.md).

After successfully creating the image on the SD card, you're ready to move on to the first step. Please do not eject the SD card yet. Remount if necessary.

1. It's recommended to enable SSH service when the Pi first boots up. To do so, add a blank `ssh` file to the `/boot` volume on the SD card as instructed in Step 3 [here](https://www.raspberrypi.org/documentation/remote-access/ssh/README.md#3-enable-ssh-on-a-headless-raspberry-pi-add-file-to-sd-card-on-another-machine).

    For example, on macOS, you can run in *Terminal:* `touch /Volumes/boot/ssh`.
    
2. **OPTIONAL:** Proceed with this step only if you confidently know your WiFi SSID and password. This is the quickest method. Otherwise, skip for now as we'll revisit the WiFi configuration on Step 6.

    Copy the [wpa_supplicant.conf](./files/wpa_supplicant.conf) file and update it, and then move the file to the `/boot` volume on the SD card. Be sure to have the SSID and password enclosed in double quotation marks.
    
   **NOTE:** The `country=` directive is set to `US`. You may need to update according to your region. Please see the enclosed link in that file for more information.

3. Eject the SD card from the computer and insert it in the Pi. Connect the Pi to your network (assuming you're home) using the Ethernet cable. Power on the Pi once connected.

	At this point, if you know the active IP address of WiFi (wlan0) interface on the Pi after completing Step 2, then you may skip the remaining steps and move on to the next [section](#run-the-playbook).

4. Since the IP address of the Pi is still unknown, a DHCP reservation list on the network is one way to address this problem. A *ping sweep* is another way to discover the Pi. The `nmap` command can get the job done.

    Here's an example command for 192.168.0.1/24 network:  
    `nmap -sn 192.168.1.0/24`
    
    Afterward, run the `arp` command to locate it:  
    `arp -an | grep -E "(b8:27:eb|dc:a6:32)"`
    
    The Pi's MAC address may begin with `b8:27:eb` (for pre-RPi4 models) or `dc:a6:32`.
    
    **HINT:** Most networks would likely allocate the same IP address to the device that previously leased it. Use this to your advantage the next time around.
    
5. With the IP address from the previous command output, you should be able to remote in using `ssh` command with the password *raspberry*.

    `ssh pi@192.168.1.10`
    
    If unsuccessful after a few minutes, then you may need to carefully redo steps from the beginning. Be sure to have the correct IP address. Although, you may get the host identification change warning. Please be sure to correct the problem as the instruction is usually provided in the warning message.
    
    You should be log in as `pi` user. Disregard the security warning for now. Proceed to switch to `root` user by running `sudo -i` command.
    
6. If you skipped Step 2, then you can proceed to setting up the WiFi here using an interactive script or otherwise you can skip this step.

    Please copy the entire content of [wifi_configurator](./files/wifi_configurator) file and paste it directly in the terminal. The interactive script would run immediately.

7. Run `ip addr show wlan0 | grep -w inet` to obtain the IP address of the WiFi connection then exit SSH.

## Run the Playbook

Before running the playbook, we'd need to first set up our environment. It's necessary that Python 3 and [SSHPass](https://gist.github.com/arunoda/7790979) are installed. While this may sounds like a bad idea, SSHPass is rather used for convenience than practice as several iterations of quick build and teardown of this appliance can be expected.

### Setup the Environment:

After installing Python and SSHPass, set up the Ansible environment:

```
git clone https://github.com/bashtheshell/raspi-firewall-tester
cd raspi-firewall-tester
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install ansible
```

Test Ansible by running the ad-hoc command (password is *raspberry*):  
`ansible all -i 192.168.0.20, -u pi --ask-pass -m ping`

In case you were wondering, the comma after the IP address is needed. If you were able to log in interactively and got `SUCCESS` in the output, this confirms SSHPass and Ansible are working.

**NOTE:** If you get the following error:  
```
FAILED! => {"msg": "Using a SSH password instead of a key is not possible because Host Key checking is enabled and sshpass does not support this.  Please add this host's fingerprint to your known_hosts file to manage this host."}
```

This means you first need to connect via `ssh` as normal so that it'll add the host's fingerprint for you. The playbook should run without issues the next time.

### Ethernet-to-WiFi Playbook:

This playbook would complete the remaining setup necessary to convert the Pi to a wireless NAT router but the network flow would be virtually non-existent at this point.

The LAN side on the Pi will have the 192.168.123.0/24 network as the Ethernet interface would be assigned the IP address, 192.168.123.1, by default as suggested in the `vars` section of the [playbook](./rpi-fw-tester_eth2wlan.yml). While it's very unlikely your home network is already on that network, if there's a conflict, then you would need to update the variable in the playbook as well as updating the DHCP range in [dnsmasq_router.conf](./files/dnsmasq_router.conf) file.

To run the playbook, you should use the WiFi IP address here:  
`ansible-playbook -i 192.168.1.20, --ask-pass -u pi rpi-fw-tester_eth2wlan.yml`

## Building the Firewall

`iptables` is undoubtedly the number one firewall choice for many Linux systems found in the wild. And for that reason, we're not going to cover a lot here as there are hundreds, if not thousands, of documentations and tutorials on how iptables works. However, what will be covered is how to configure the iptables to act as a NAT router, blacklisting all traffic by default. Even with this Raspberry Pi appliance, you can safely experiment the `iptables` command by using several freely available tutorials after reading the remaining instruction.

By default, iptables uses the *filter* table, which we will use quite often. This means we do not have to run the command with `-t filter` option every time. *nat* table would be set up only once to configure masquerading rule in the `POSTROUTING` chain.

It's important to know that the policy target (`-P`) that is set for all built-in chains (`INPUT`, `FORWARD`, and `OUTPUT`) are defaulted to `ACCEPT` packets as indicated in `iptables -S` command output. However, for the purpose of this appliance, we'd need to set the `FORWARD` chain to `DROP` packets by default, which we'll get to later.

The `FORWARD` chain is the only filtering chain that gets to dictate how the traffic flows from one interface to another interface while the `INPUT` and `OUTPUT` chains are only for traffic originating from and traveling to the Pi itself.

### Test and Observe:

It's generally agreed the quickest and fun way to learn is to get some hands-on experience. We'll start with a fully-functioning NAT router setup. Please remember the iptables will lose all of the running configurations in an event of power loss or reboot. This is to be expected as this testing appliance shouldn't persistently store the firewall rules.

Now, SSH into the Pi and then switch to root user using `sudo -i` command. 

Ensure the policy target is at its default by running:  
```
iptables --policy INPUT ACCEPT
iptables --policy OUTPUT ACCEPT
iptables --policy FORWARD ACCEPT
```

The commands would apply immediately.

---

#### For Ethernet to WiFi:

By now you should connect the Ethernet cable from the Pi to your computer.

Next, add the following rule. This should never be removed for later steps but feel free to test without it now to see why not then reboot the Pi and resume back here.

`iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE`

Now you'd get a working NAT router as the `FORWARD` chain is forwarding all traffic! However, the setup isn't quite complete as unauthorized outside traffic can still penetrate to the LAN somehow as implied by the existing rules. To complete it, add the following:

```
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -j ACCEPT
```

To view the current firewall table in a human-readable format:  
`iptables -nvL --line-numbers`

Now for a little fun, we can go ahead insert the rules at the top of the two rules we added to the `FORWARD` chain. Instead of using `-A`, which stands for *append*, we'll *insert* (`-I`). The following rules will block HTTP and HTTPS traffic at TCP port 80 and 443, respectively. Try adding a line at a time and test the rule. You'd see that some websites may not work as they do not properly redirect to HTTPS when they should.

```
iptables -I FORWARD -i eth0 -o wlan0 -p tcp --dport 80 -j DROP
iptables -I FORWARD -i eth0 -o wlan0  -p tcp --dport 443 -j DROP
```

While you may think the lines below would work just fine too:  
```
iptables -A FORWARD -p tcp --dport 80 -j DROP
iptables -A FORWARD -p tcp --dport 443 -j DROP
```

The problem is that it'd also block outside traffic if you ever decide to set up a web server on the LAN side of the Pi. So it's best to be as specific as possible using the correct network interfaces.

We had enough fun. Please reboot the Pi to clear the iptables.

---

### Deploying Setup:

For the setup, we're now going to update the policy target to `DROP` packets when there's no matching rules left in the chain.

```
iptables --policy INPUT ACCEPT
iptables --policy OUTPUT ACCEPT
iptables --policy FORWARD DROP
```

---

#### For Ethernet to WiFi:

Again, this rule is important to add as it's the essence of a NAT router.  
`iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE`

Finally, we're going to allow only HTTP and HTTPS traffics as all traffics are denied by default according to the policy target.

```
iptables -I FORWARD -i eth0 -o wlan0 -p tcp --dport 80 -j ACCEPT
iptables -I FORWARD -i eth0 -o wlan0  -p tcp --dport 443 -j ACCEPT
iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

It's also very important that the last rule, as shown below, stays on the bottom of the chain as we'd need to allow permissible connections that originated from the LAN side to maintain connectivity. Notice the `-I` and `-A` options here? New custom rules should always be inserted on the top. The order doesn't matter as long as the last rule remains last.

`iptables -A FORWARD -i wlan0 -o eth0 -m state --state RELATED,ESTABLISHED -j ACCEPT`

You should be able to browse the Internet. Although, you may notice other apps using different services that may not work completely at this point.

---

You can also delete a specific rule in the chain by using the number shown in the output of `iptables -nvL --line-numbers`. `iptables -D FORWARD 2` would delete the 2nd rule currently listed in the `FORWARD` chain. However, if you attempt to run the command again, you would either delete what was previously the 3rd rule listed or an invalid rule number due to only having one rule left.

## What's Next?

So far, we've seen the wireless NAT router in action! Although, this appliance is only compatible with Ethernet-enabled devices such as laptops and desktop computers. 

What about mobile devices? That can be arranged in a future development using `hostapd` (host access point daemon), which is responsible for broadcasting WiFi SSID to the LAN. We can flip the direction with both interfaces!

It'd be a great pleasure to see some pull requests on the ideas mentioned above as I've decided to take a break for now. Thanks in advance for contributing if you've decided to do so.

## Known Issue?

Nothing I can identify at this time. Please submit an issue if you see a problem. Thanks!

