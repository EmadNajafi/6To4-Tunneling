#!/bin/bash

# ---- رنگ‌ها برای خروجی زیباتر ----
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ---- خروج تمیز با Trap ----
cleanup() {
    echo -e "\n${YELLOW}Exiting... Goodbye!${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

# ---- تابع چاپ با تاخیر ----
print() {
    local text="$1"
    local delay="${2:-0.04}"
    for ((i=0; i<${#text}; i++)); do
        echo -ne "${text:$i:1}"
        sleep "$delay"
    done
    echo
}

# ---- تابع چک وابستگی ----
check_dep() {
    command -v "$1" >/dev/null 2>&1 || {
        echo -e "${RED}Error: '$1' is not installed. Please install it first.${NC}"
        exit 1
    }
}

# ---- نمایش منو ----
show_menu() {
    echo -e "\n${GREEN}========== Main Menu ==========${NC}"
    echo "1) Tunnel"
    echo "2) Install Sanaei x-ui"
    echo "3) Install ShaHan SSH Panel"
    echo "0) Exit"
    echo -e "${GREEN}===============================${NC}\n"
}

# ---- اجرای ایمن اسکریپت‌های خارجی ----
run_remote_script() {
    local url="$1"
    check_dep curl
    if curl --output /dev/null --silent --head --fail "$url"; then
        bash <(curl -Ls "$url")
        local status=$?
        if [ $status -ne 0 ]; then
            echo -e "${RED}Script execution failed with exit code $status.${NC}"
        fi
    else
        echo -e "${RED}Error: Unable to reach $url${NC}"
    fi
}

# ---- توابع گزینه‌ها ----
tunnel() {
    run_remote_script "https://raw.githubusercontent.com/EmadNajafi/6To4-Tunneling/main/tunnel.sh"
}

sanaei() {
    run_remote_script "https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh"
}

shahan() {
    run_remote_script "https://raw.githubusercontent.com/HamedAp/Ssh-User-management/master/install.sh"
}

# ---- هندل ورودی کاربر ----
handle_choice() {
    case "$1" in
        1) tunnel ;;
        2) sanaei ;;
        3) shahan ;;
        0)
            cleanup
            ;;
        *)
            echo -e "${RED}Invalid option! Please select a valid number.${NC}"
            sleep 1
            ;;
    esac
}

# ---- اجرای اسکریپت ----
clear
print "Written By EmadNajafi" 0.03
sleep 0.7

while true; do
    clear
    show_menu
    read -rp "$(echo -e "${YELLOW}Please enter a number: ${NC}")" number
    handle_choice "$number"
done
