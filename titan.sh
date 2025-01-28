#!/bin/bash

# Color and formatting definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
WHITE='\033[37m'
RESET='\033[0m'

# Icons for menu options
ICON_TELEGRAM="🚀"
ICON_INSTALL="🛠️"
ICON_LOGS="📄"
ICON_STOP="⏹️"
ICON_START="▶️" 
ICON_WALLET="💰"
ICON_UPDATE="🔄"
ICON_RESTART="♻️"
ICON_EXIT="❌"

LATEST_VERSION=$(curl -s https://api.github.com/repos/Titannet-dao/titan-node/releases/latest | jq -r '.tag_name')
print_logo() {
    curl https://raw.githubusercontent.com/cainnech01/chain_nodes/refs/heads/main/logo.sh | bash
}

install_node() { 
    echo -e "${GREEN}🛠️  Installing or Updating Node...${RESET}"
    install_prequisites
    
    wget --quiet --show-progress "https://github.com/Titannet-dao/titan-node/releases/download/$LATEST_VERSION/titan-edge_${$LATEST_VERSION}_246b9dd_linux-amd64.tar.gz" -O "titan-edge_${LATEST_VERSION}_246b9dd_linux-amd64.tar.gz"
    tar -xzf "titan-edge_${LATEST_VERSION}_246b9dd_linux-amd64.tar.gz" > /dev/null
    cd "titan-edge_${LATEST_VERSION}_246b9dd_linux-amd64" || { show "Failed to change directory."; exit 1; }

    sudo cp titan-edge /usr/local/bin
    sudo cp libgoworkerd.so /usr/local/lib
    export LD_LIBRARY_PATH=$LD_LIZBRARY_PATH:./libgoworkerd.so
    titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0
}

start_node() {
    cd "titan-edge_${LATEST_VERSION}_246b9dd_linux-amd64" || { show "Failed to change directory."; exit 1; }

    titan-edge daemon start
}

stop_node() {
    cd "titan-edge_${LATEST_VERSION}_246b9dd_linux-amd64" || { show "Failed to change directory."; exit 1; }

    titan-edge daemon stop
}

install_prequisites() {
    if ! command -v jq &> /dev/null; then
        show "jq not found, installing..."
        sudo apt-get update
        sudo apt-get install -y jq tar > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            show "Failed to install jq. Please check your package manager."
            exit 1
        fi
    fi

}

while true; do
    show_menu() {
        clear
        print_logo
        echo -e "    ${WHITE}Please choose an option:${RESET}"
        echo
        echo -e "    ${WHITE}1.${RESET} ${ICON_INSTALL} Install/Update Node"
        echo -e "    ${WHITE}2.${RESET} ${ICON_STOP} Stop Node"
        echo -e "    ${WHITE}3.${RESET} ${ICON_START} Start Node"
        echo -e "    ${WHITE}4.${RESET} ${ICON_INSTALL} Install Prequisites"
        echo -e "    ${WHITE}0.${RESET} ${ICON_EXIT} Exit"
        echo -ne "    ${GREEN}Enter your choice [0-6]:${RESET} "
        read choice
    }

    show_menu

    case $choice in
        1) install_node ;;
        2) stop_node ;;
        3) start_node ;;
        4) install_prequisites ;;
        0) echo -e "${GREEN}❌ Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option. Please try again.${RESET}"; sleep 2 ;;
    esac
done