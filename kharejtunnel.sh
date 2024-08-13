#!/bin/bash
print() {
    text="$1"
    delay="$2"
    for ((i=0; i<${#text}; i++)); do
        echo -n "${text:$i:1}"
        sleep $delay
    done
    echo
}
clear
echo ""
print "6To4 / Gre6 Tunneling...!" 0.10
echo ""

sed -i 's/#Port 22/Port 22/' /etc/ssh/sshd_config
po=$(cat /etc/ssh/sshd_config | grep "^Port")
port=$(echo "$po" | sed "s/Port //g")
ipkharej=$(curl -s ipv4.icanhazip.com)


echo "\nIp Kharej ro vared konid : "
printf "Ip Server Kharej Shoma : \e[33m${ipkharej}\e[0m, Baraye Taeid Enter Bznid... "
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
