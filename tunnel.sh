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

##tunnelmenu##
tunnelmenu () { while true
do
clear
echo "Tunnel Menu"
echo ""
echo "1: 6To4/Gre6 Iran"
echo "2: 6To4/Gre6 Kharej"
echo "3: Nat Forwarding"
echo "4: Port Forwarding"
echo ""
echo "0: Back To Main Menu.."
echo ""
read -p "Please enter a number: " number
echo ""
case $number in
    1) iran;;
    2) kharej;;
    3) iptable;;
    4) port;;
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

    clear
    echo ""
    print "Done...!" 0.20
    echo ""
    clear

}

##Port Forwarding##
port() {
    sudo sysctl net.ipv4.ip_forward=1
    sudo iptables -A INPUT -i lo -j ACCEPT
    sudo iptables -A OUTPUT -o lo -j ACCEPT
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.13.1
    iptables -t nat -A PREROUTING -p tcp --dport 1:65535 -j DNAT --to-destination 192.168.13.2:1-65535
    iptables -t nat -A PREROUTING -p udp --dport 1:65535 -j DNAT --to-destination 192.168.13.2:1-65535
    sudo iptables -t nat -A POSTROUTING -j MASQUERADE


    clear
    echo ""
    print "Done...!" 0.20
    echo ""
    clear
}

back () {
    bash <(curl -Ls https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/mainmenu.sh)
}

tunnelmenu

