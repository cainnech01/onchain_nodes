#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
RESET='\033[0m'

CHECKMARK="✅"
ERROR="❌"
PROGRESS="⏳"
INSTALL="🛠️"
STOP="⏹️"
RESTART="🔄"
LOGS="📄"
EXIT="🚪"
INFO="ℹ️"

print_logo() {
    curl https://raw.githubusercontent.com/cainnech01/chain_nodes/refs/heads/main/logo.sh | bash
}

install_prerequisites() {
    sudo apt update && sudo apt upgrade -y
    packages=("unzip" "libasound2" "libasound2t64" "libgtk-3-0" "libnotify4" "libnss3" "libxss1" "libxtst6" "xdg-utils" "libatspi2.0-0" "libsecret-1-0" "libgbm1" "desktop-file-utils")
    for package in "${packages[@]}"; do
        if ! dpkg -l | grep -i $package &>/dev/null; then
            echo -e "${ERROR} $package is not installed. Installing...${RESET}"
            sudo apt-get install -y $package
        else
            echo -e "${CHECKMARK} $package is already installed.${RESET}"
        fi
    done
    echo -e "${INSTALL} Installing Docker and Docker Compose...${RESET}"
    sudo apt install docker.io -y
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo curl -L "https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${CHECKMARK} Docker and Docker Compose installed successfully.${RESET}"
}

install_node() {
    echo -e "${GREEN}🟢 Installing node...${RESET}"
    install_prerequisites

    wget https://cdn.openledger.xyz/openledger-node-1.0.0-linux.zip
    unzip openledger-node-1.0.0-linux.zip
    sudo dpkg -i openledger-node-1.0.0.deb

    echo -e "${CHECKMARK} OpenLedger installed successfully.${RESET}"
    read -p "Press Enter to continue..."
}

start_node() {
    echo -e "${PROGRESS} Starting OpenLedger Node...${RESET}"
    openledger-node --no-sandbox
    echo -e "${CHECKMARK} OpenLedger Node started.${RESET}"
    read -p "Press Enter to continue..."
}

stop_node() {
    echo -e "${PROGRESS} Stopping OpenLedger Node...${RESET}"
    stop opl_scraper opl_worker
    echo -e "${CHECKMARK} OpenLedger Node stopped.${RESET}"
    read -p "Press Enter to continue..."
}

draw_menu() {
    clear
    print_logo
    echo -e "    ${WHITE}Choose an option:${RESET}"
    echo -e "    ${WHITE}1.${RESET} ${INSTALL} Install OpenLedger"
    echo -e "    ${WHITE}2.${RESET} ${STOP} Stop OpenLedger Containers"
    echo -e "    ${WHITE}3.${RESET} ${INSTALL} Start OpenLedger Node"
    echo -e "    ${WHITE}4.${RESET} ${EXIT} Exit"
    echo -ne "    ${WHITE}Enter your choice [1-4]: ${RESET}"
}

while true; do
    draw_menu
    read choice
    case $choice in
        1)
            install_node
            ;;
        2)
            stop_node
            ;;
        3)
            start_node
            ;;
        4)
            echo -e "${EXIT} Exiting...${RESET}"
            exit 0
            ;;
        *)
            echo -e "${ERROR} Invalid option. Please try again.${RESET}"
            read -p "Press Enter to continue..."
            ;;
    esac
done