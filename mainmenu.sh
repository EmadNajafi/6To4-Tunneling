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
print "Written By EmadNajafi" 0.10
echo ""

clear

##Main Menu##
menu () { while true 
do
clear
echo "Simple Script!"
echo ""
echo "1: Tunnel"
echo "2: Install Sanaei x-ui"
echo "3: Install ShaHan SSH Panel"
echo "0: Exit"
echo ""
read -p "Please enter a number: " number
case $number in
	1) tunnel;;
	2) sanaei;;
	3) shahan;;
	0) exit;;
esac
done
}

##Tunnel##
tunnel() {
	bash <(curl -Ls https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/tunnel.sh)
}


##Install Sanaei x-ui Panel##
sanaei() {
	bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
}

##Insall Shahan SSH Panel##
shahan() {
	bash <(curl -Ls https://raw.githubusercontent.com/HamedAp/Ssh-User-management/master/install.sh)
}

menu
