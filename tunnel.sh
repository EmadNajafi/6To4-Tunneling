#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'


print() {
    local text="$1"
    local delay="${2:-0.03}"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

require_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}In script bayad ba dastresi root ejra beshe.${NC}"
        exit 1
    fi
}

check_deps() {
    for cmd in curl ip iptables sed; do
        command -v "$cmd" &>/dev/null || { echo -e "${RED}Vabastegi '$cmd' peyda nashod. Lotfan nasbesh kon.${NC}"; exit 1; }
    done
}

cleanup() {
    echo -e "\n${YELLOW}Khorooj az barname...${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

iran() {
    require_root
    check_deps

    sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    port=$(grep "^Port" /etc/ssh/sshd_config | sed "s/Port //g")
    ipiran=$(curl -s ipv4.icanhazip.com || echo "N/A")

    echo -e "IP Iran shenasaei shode: ${YELLOW}${ipiran}${NC}"
    read -rp "Agar mikhay IP Iran ro taghir bedi benevis (ya Enter bezan): " irtmp
    [[ -n "$irtmp" ]] && ipiran="$irtmp"

    read -rp "IP server kharej ro vared kon: " ipkharej
    [[ -z "$ipkharej" ]] && { echo -e "${RED}IP kharej ejbari ast.${NC}"; sleep 1; return; }

    
    cat <<EOF | tee /etc/sysctl.d/60-custom.conf >/dev/null
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sysctl -p /etc/sysctl.d/60-custom.conf

    ip tunnel add 6to4_To_KH mode sit remote "$ipkharej" local "$ipiran"
    ip -6 addr add fc00::1/64 dev 6to4_To_KH
    ip link set 6to4_To_KH mtu 1480
    ip link set 6to4_To_KH up

    ip -6 tunnel add GRE6Tun_To_KH mode ip6gre remote fc00::2 local fc00::1
    ip addr add 192.168.13.1/30 dev GRE6Tun_To_KH
    ip link set GRE6Tun_To_KH mtu 1436
    ip link set GRE6Tun_To_KH up

    echo
    print "Tamoom shod!" 0.06
    sleep 1
}

kharej() {
    require_root
    check_deps

    sed -i 's/^#Port 22/Port 22/' /etc/ssh/sshd_config
    port=$(grep "^Port" /etc/ssh/sshd_config | sed "s/Port //g")
    ipkharej=$(curl -s ipv4.icanhazip.com || echo "N/A")

    echo -e "IP kharej shenasaei shode: ${YELLOW}${ipkharej}${NC}"
    read -rp "Agar mikhay IP kharej ro taghir bedi benevis (ya Enter bezan): " khtmp
    [[ -n "$khtmp" ]] && ipkharej="$khtmp"

    read -rp "IP server Iran ro vared kon: " ipiran
    [[ -z "$ipiran" ]] && { echo -e "${RED}IP Iran ejbari ast.${NC}"; sleep 1; return; }

    # Tanzimat shabake va tunnel
    cat <<EOF | tee /etc/sysctl.d/60-custom.conf >/dev/null
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
EOF
    sysctl -p /etc/sysctl.d/60-custom.conf

    ip tunnel add 6to4_To_IR mode sit remote "$ipiran" local "$ipkharej"
    ip -6 addr add fc00::2/64 dev 6to4_To_IR
    ip link set 6to4_To_IR mtu 1480
    ip link set 6to4_To_IR up

    ip -6 tunnel add GRE6Tun_To_IR mode ip6gre remote fc00::1 local fc00::2
    ip addr add 192.168.13.2/30 dev GRE6Tun_To_IR
    ip link set GRE6Tun_To_IR mtu 1436
    ip link set GRE6Tun_To_IR up

    echo
    print "Tamoom shod!" 0.06
    sleep 1
}

nat_forward() {
    require_root
    check_deps

    sysctl net.ipv4.ip_forward=1
    iptables -t nat -A PREROUTING -p tcp --dport 22 -j DNAT --to-destination 192.168.13.1
    iptables -t nat -A PREROUTING -j DNAT --to-destination 192.168.13.2
    iptables -t nat -A POSTROUTING -j MASQUERADE

    echo
    print "Tamoom shod!" 0.06
    sleep 1
}

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
    print "Tamoom shod!" 0.06
    sleep 1
}

# ========== Menu Tunnel ==========
tunnel_menu() {
    while true; do
        clear
        echo -e "${GREEN}========== Tunnel Menu ==========${NC}"
        echo "1) 6To4/Gre6 Iran"
        echo "2) 6To4/Gre6 Kharej"
        echo "3) NAT Forwarding"
        echo "4) Port Forwarding"
        echo "0) Bargasht be menu asli"
        echo -e "${GREEN}=================================${NC}\n"
        read -rp "$(echo -e "${YELLOW}Shomare ra vared konid: ${NC}")" number
        echo
        case $number in
            1) iran ;;
            2) kharej ;;
            3) nat_forward ;;
            4) port_forward ;;
            0) return ;; # Bargasht be menu asli
            *) echo -e "${RED}Entekhab namotabar! Dobare talash kon.${NC}"; sleep 1 ;;
        esac
    done
}

# ========== Nasb panel-ha ==========
sanaei() {
    bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
}
shahan() {
    bash <(curl -Ls https://raw.githubusercontent.com/HamedAp/Ssh-User-management/master/install.sh)
}

# ========== Menu asli ==========
main_menu() {
    while true; do
        clear
        echo -e "${GREEN}========== Main Menu ==========${NC}"
        echo "1) Tunnel"
        echo "2) Nasb Sanaei x-ui"
        echo "3) Nasb ShaHan SSH Panel"
        echo "0) Khorooj"
        echo -e "${GREEN}===============================${NC}\n"
        read -rp "$(echo -e "${YELLOW}Shomare ra vared konid: ${NC}")" number
        echo
        case $number in
            1) tunnel_menu ;;
            2) sanaei ;;
            3) shahan ;;
            0) cleanup ;;
            *) echo -e "${RED}Entekhab namotabar! Dobare talash kon.${NC}"; sleep 1 ;;
        esac
    done
}

# ========== Ejraye barname ==========
clear
require_root
check_deps
print "Written By EmadNajafi" 0.04
sleep 0.7
main_menu
