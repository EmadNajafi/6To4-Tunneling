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
print "Written By Emad Najafi" 0.10
echo ""

##Main Menu##
menu () { while true 
do
echo "Simple Script!"
echo ""
echo "1: Iran"
echo "2: Kharej"
echo "3: Install Sanaei x-ui"
echo "4: Install ShaHan SSH Panel"
echo "0: Exit"
echo ""
read -p "Please enter a number: " number
case $number in
	1) iran;;
	2) kharej;;
	3) sanaei;;
	4) shahan;;
	0) exit;;
esac
done
}

##Server Iran Codes##
iran() { 
	bash <(curl -Ls https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/irantunnel.sh)
}

##Server Kharej Codes##
kharej() {
	bash <(curl -Ls https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/kharejtunnel.sh)
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
