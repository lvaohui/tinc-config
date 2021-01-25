#!/bin/bash

read -p 'Net name [default: vpn]' net_name
read -p 'Host name [default: node0]' host_name
read -p 'Interface [default: tun0]' interface
read -p $'client or server?\n0 client\n1 server\nchoice [default: 0]' cs

set_default(){
    if [ -z "`eval echo '$'"${1}"`" ]
    then
        eval $1=$2
    fi
}

set_default net_name vpn
set_default host_name node0
set_default interface tun0
set_default cs 0

#echo $net_name $host_name $interface $cs

if [ $cs = 0 ]
then
    read -p 'the server host name you will connect:' server_name
elif [ $cs = 1 ]
then
    read -p 'Global Ipv4 Address(if not,leave it blank):' ipv4_addr
    read -p 'Global Ipv6 Address(if not,leave it blank):' ipv6_addr
    read -p 'Listen Port[default: 655]' port
fi
set_default port 655

read -p 'Local ipv4 address[default: 10.0.0.1/24]:' local_ipv4_addr
read -p 'Local ipv6 address[default: fec0::1/64]:' local_ipv6_addr

set_default local_ipv4_addr "10.0.0.1/24"
set_default local_ipv6_addr "fec0::1/64"

read -p 'Number of Share Subnet[default: 0]' num
set_default num 0

if [ $num > 0 ]
then
    echo 'Please input Subnet(format:10.2.7.0/24 or ::/0)'
fi

for ((i=0;i<$num;i++))
do
    read -p "Subnet $i :" subnet[$i]
done

echo '---Start generating configuration file---'
sudo mkdir -p /etc/tinc/$net_name/hosts
sudo chmod -R 755 /etc/tinc/$net_name
cd /etc/tinc/$net_name/

############# tinc.conf ################
sudo touch tinc.conf

sudo echo "Name = $host_name" | sudo tee -a  tinc.conf 
sudo echo "AddressFamily = any" | sudo tee -a  tinc.conf
if [ $cs = 0 ]
then
    sudo echo "ConnectTo = $server_name" | sudo tee -a  tinc.conf
elif [ $cs = 1 ]
then
    sudo echo "BindToAddress = * $port" | sudo tee -a  tinc.conf
fi
sudo echo "Interface = $interface" | sudo tee -a  tinc.conf
sudo echo "Device = /dev/net/tun" | sudo tee -a  tinc.conf
sudo echo "PrivateKeyFile=/etc/tinc/$net_name/rsa_key.priv" | sudo tee -a  tinc.conf

############### tinc-up #################
sudo touch tinc-up
sudo echo "#!/bin/sh" | sudo tee -a  tinc-up
sudo echo "ip addr add $local_ipv4_addr dev \$INTERFACE" | sudo tee -a  tinc-up
sudo echo "ip -6 addr add $local_ipv6_addr dev \$INTERFACE" | sudo tee -a  tinc-up
sudo echo "ip link set \$INTERFACE up" | sudo tee -a  tinc-up

############### tinc-down ################
sudo touch tinc-down
sudo echo "#!/bin/sh" | sudo tee -a  tinc-down
sudo echo "ip route del $local_ipv4_addr dev \$INTERFACE" | sudo tee -a  tinc-down
sudo echo "ip -6 route del $local_ipv6_addr dev \$INTERFACE" | sudo tee -a  tinc-down
sudo echo "ifconfig \$INTERFACE down" | sudo tee -a  tinc-down

if [ $num > 0 ]
then
    sudo echo "echo 1 > /proc/sys/net/ipv4/ip_forward" | sudo tee -a tinc-up
    sudo echo "echo 0 > /proc/sys/net/ipv4/ip_forward" | sudo tee -a tinc-down
    sudo echo "iptables -t nat -A POSTROUTING -s $local_ipv4_addr -j MASQUERADE" | sudo tee -a tinc-up
    sudo echo "iptables -t nat -D POSTROUTING -s $local_ipv4_addr -j MASQUERADE" | sudo tee -a tinc-down
fi

sudo chmod +x tinc-*

############### host_name ################
cd hosts
sudo touch $host_name
if [ $cs = 1 ]
then
    if [ -n "$ipv4_addr" ]
    then
        sudo echo "Address=$ipv4_addr" | sudo tee -a  $host_name
    fi
    if [ -n "$ipv6_addr" ]
    then
        sudo echo "Address=$ipv6_addr" | sudo tee -a  $host_name
    fi
    sudo echo "Port=$port" | sudo tee -a  $host_name
fi
sudo echo "Subnet=`sudo echo $local_ipv4_addr | awk -F/ '{print $1}'`/32" | sudo tee -a  $host_name
sudo echo "Subnet=`sudo echo $local_ipv6_addr | awk -F/ '{print $1}'`/128" | sudo tee -a  $host_name
for ((i=0;i<$num;i++))
do
    sudo echo "Subnet=${subnet[$i]}" | sudo tee -a  $host_name
done

sudo tincd -n $net_name -K 4096

echo "done"
echo "start command: sudo tincd -n netname"
echo "stop command: sudo tincd -n netname -k"
echo "use systemctl enable tinc@netname to enable individual networks"
