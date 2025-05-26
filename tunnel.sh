#!/bin/bash

# رنگ‌ها
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# تابع چاپ کاراکتر به کاراکتر
print() {
    local text="$1"
    local delay="${2:-0.03}"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# چک دسترسی روت
require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}This script must be run as root.${NC}"
        exit 1
    fi
}

# چک وابستگی‌های ضروری
check_deps() {
    for cmd in curl ip iptables sed; do
        command -v "$cmd" &>/dev/null || { echo -e "${RED}Dependency '$cmd' not found. Install it first.${NC}"; exit 1; }
    done
}

# Tunnel Menu
tunnel_menu() {
    while true; do
        clear
        echo -e "${GREEN}========== Tunnel Menu ==========${NC}"
        echo "1) 6To4/Gre6 Iran"
        echo "2) 6To4/Gre6 Kharej"
        echo "3) NAT Forwarding"
        echo "4) Port Forwarding"
        echo "0) Back To Main Menu"
        echo -e "${GREEN}=================================${NC}\n"
        read -rp "$(echo -e "${YELLOW}Please enter a number: ${NC}")" number
        echo
        case $number in
            1) iran ;;
            2) kharej ;;
            3) nat_forward ;;
            4) port_forward ;;
            0) back ;;
            *) echo -e "${RED}Invalid choice. Please try again.${NC}"; sleep 1 ;;
        esac
    done
}

# تابع ایران
iran() {
    require_root
    check_deps

    sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    port=$(grep "^Port" /etc/ssh/sshd_config | sed "s/Port //g")
    ipiran=$(curl -s ipv4.icanhazip.com || echo "N/A")

    echo -e "Detected Iran Server IP: ${YELLOW}${ipiran}${NC}"
    read -rp "Enter Iran Server IP (leave empty to use detected): " irtmp
    [[ -n "$irtmp" ]] && ipiran="$irtmp"

    read -rp "Enter Foreign Server IP: " ipkharej
    [[ -z "$ipkharej" ]] && { echo -e "${RED}Foreign Server IP is required.${NC}"; return; }

    # تنظیمات شبکه و تونل
    cat <<EOF | sudo tee /etc/sysctl.d/60-custom.conf >/dev/null
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sudo sysctl -p /etc/sysctl.d/60-custom.conf

    ip tunnel add 6to4_To_KH mode sit remote "$ipkharej" local "$ipiran"
    ip -6 addr add fc00::1/64 dev 6to4_To_KH
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up

    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fc00::2 local fc00::1
    ip addr add 192.168.13.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up

    echo
    print "Done!" 0.06
    sleep 1
}

# تابع خارج
kharej() {
    require_root
    check_deps

    sudo sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    port=$(grep "^Port" /etc/ssh/sshd_config | sed "s/Port //g")
    ipkharej=$(curl -s ipv4.icanhazip.com || echo "N/A")

    echo -e "Detected Foreign Server IP: ${YELLOW}${ipkharej}${NC}"
    read -rp "Enter Foreign Server IP (leave empty to use detected): " khtmp
    [[ -n "$khtmp" ]] && ipkharej="$khtmp"

    read -rp "Enter Iran Server IP: " ipiran
    [[ -z "$ipiran" ]] && { echo -e "${RED}Iran Server IP is required.${NC}"; return; }

    # تنظیمات شبکه و تونل
    cat <<EOF | sudo tee /etc/sysctl.d/60-custom.conf >/dev/null
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sudo sysctl -p /etc/sysctl.d/60-custom.conf

    ip tunnel add 6to4_To_IR mode sit remote "$ipiran" local "$ipkharej"
    ip -6 addr add fc00::2/64 dev 6to4_To_IR
    ip link set 6to4_To_IR mtu 1480
    ip link set 6to4_To_IR up

    ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fc00::1 local fc00::2
    ip addr add 192.168.13.2/30 dev GRE6Tun_To_IR
    ip link set GRE6Tun_To_IR mtu 1436
    ip link set GRE6Tun_To_IR up

    echo
    print "Done!" 0.06
    sleep 1
}

# NAT Forwarding (قبلی iptable)
nat_forward() {
    require_root
    check_deps

    sysctl net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.13.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 192.168.13.2
    iptables -t nat -A POSTROUTING -j MASQUERADE

    echo
    print "Done!" 0.06
    sleep 1
}

# Port Forwarding
port_forward() {
    require_root
    check_deps

    sysctl net.ipv4.ip_forward=1
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A OUTPUT -o lo -j ACCEPT
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.13.1
    iptables -t nat -A PREROUTING -p tcp --dport 1:65535 -j DNAT --to-destination 192.168.13.2
    iptables -t nat -A PREROUTING -p udp --dport 1:65535 -j DNAT --to-destination 192.168.13.2
    iptables -t nat -A POSTROUTING -j MASQUERADE

    echo
    print "Done!" 0.06
    sleep 1
}

# برگشت به منوی اصلی
back() {
    curl -Ls https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/mainmenu.sh | bash
    exit 0
}

# اجرای منو
tunnel_menu
