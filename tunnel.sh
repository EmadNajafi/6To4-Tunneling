#!/bin/bash

##tunnelmenu##
tunnelmenu () { while true
do
clear
echo "Tunnel Menu"
echo ""
echo "1: 6To4/Gre6 Iran"
echo "2: 6To4/Gre6 Kharej"
echo "3: Start Tunnel With iptable"
echo ""
echo "0: Back To Main Menu...!"
echo ""
read -p "Please enter a number: " number
case $number in
    1) iran;;
    2) kharej;;
    3) iptable;;
    0) back;;
esac
done
}

##6to4/gre6-iran##
iran() {
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
po=$(cat /etc/ssh/sshd_config | grep "^Port")
port=$(echo "$po" | sed "s/Port //g")
ipiran=$(curl -s ipv4.icanhazip.com)



printf "Ip Server Iran Shoma : \e[33m${ipiran}\e[0m, Baraye Taeid Enter Bznid..."
echo -e "\nIp Iran ro vared konid : "
read irtmp
if [[ -n "${irtmp}" ]]; then
    ipiran=${irtmp}
fi

echo ""
echo -e "\nIp Server kharej ro vared konid : "
read khtmp
if [[ -n "${khtmp}" ]]; then
    ipkharej=${khtmp}
fi


echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/60-custom.conf
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/60-custom.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/60-custom.conf
sudo sysctl -p /etc/sysctl.d/60-custom.conf

ip tunnel add 6to4_To_KH mode sit remote $ipkharej local $ipiran
ip -6 addr add fc00::1/64 dev 6to4_To_KH
ip link set 6to4_To_KH mtu 1480
ip link set 6to4_To_KH up

ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fc00::2 local fc00::1
ip addr add 192.168.13.1/30 dev GRE6Tun_To_KH
ip link set GRE6Tun_To_KH mtu 1436
ip link set GRE6Tun_To_KH up


clear
echo ""
print "Done...!" 0.20
echo ""
clear
}


##kharej##
kharej(){
    sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
po=$(cat /etc/ssh/sshd_config | grep "^Port")
port=$(echo "$po" | sed "s/Port //g")
ipkharej=$(curl -s ipv4.icanhazip.com)


printf "Ip Server Kharej Shoma : \e[33m${ipkharej}\e[0m, Baraye Taeid Enter Bznid... "
echo -e "\nIp Kharej ro vared konid : "
read khtmp
if [[ -n "${khtmp}" ]]; then
    ipkharej=${khtmp}
fi


echo -e "\nIp Server Iran ro vared konid : "
read irtmp
if [[ -n "${irtmp}" ]]; then
    ipiran=${irtmp}
fi


echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/60-custom.conf
echo "net.core.default_qdisc=fq" | sudo tee -a /etc/sysctl.d/60-custom.conf
echo "net.ipv4.tcp_congestion_control=bbr" | sudo tee -a /etc/sysctl.d/60-custom.conf
sudo sysctl -p /etc/sysctl.d/60-custom.conf

ip tunnel add 6to4_To_IR mode sit remote $ipiran local $ipkharej
ip -6 addr add fc00::2/64 dev 6to4_To_IR
ip link set 6to4_To_IR mtu 1480
ip link set 6to4_To_IR up

ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fc00::1 local fc00::2
ip addr add 192.168.13.2/30 dev GRE6Tun_To_IR
ip link set GRE6Tun_To_IR mtu 1436
ip link set GRE6Tun_To_IR up

clear
echo ""
print "Done...!" 0.20
echo ""
clear
}


##Ip Tabeles To local Ips##
iptable() {
    sysctl net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.13.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 192.168.13.2
    iptables -t nat -A POSTROUTING -j MASQUERADE
}

##Back To Mainmenu##
back() {
    bash <(curl -Ls https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/mainmenu.sh)
}
tunnelmenu

