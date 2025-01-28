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

# Functions to draw borders and display menu
print_logo() {
    curl https://raw.githubusercontent.com/cainnech01/chain_nodes/refs/heads/main/logo.sh | bash
    echo -e "          ${WHITE}${ICON_TELEGRAM} Follow us on Telegram!${RESET}"
}

show() {
    echo -e "\033[1;35m$1\033[0m"
}

# Function to check and install jq if not present
install_jq() {
    if ! command -v jq &> /dev/null; then
        show "jq not found, installing..."
        sudo apt-get update
        sudo apt-get install -y jq > /dev/null 2>&1
        if [ $? -ne 0 ]; then
            show "Failed to install jq. Please check your package manager."
            exit 1
        fi
    fi
}

# Function to check the latest version from GitHub
check_latest_version() {
    for i in {1..3}; do
        LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | jq -r '.tag_name')
        if [ -n "$LATEST_VERSION" ]; then
            show "Latest version available: $LATEST_VERSION"
            return 0
        fi
        show "Attempt $i: Failed to fetch the latest version. Retrying..."
        sleep 2
    done

    show "Failed to fetch the latest version after 3 attempts. Please check your internet connection or GitHub API limits."
    exit 1
}

# Function to install or update the node
install_update_node() {
    echo -e "${GREEN}🛠️  Installing or Updating Node...${RESET}"
    
    install_jq
    check_latest_version  # Function to fetch the latest version

    download_required=true

    if [ -d "executor-linux-${LATEST_VERSION}" ]; then
        show "Latest version is already downloaded. Skipping download."
        cd "executor-linux-${LATEST_VERSION}" || { show "Failed to change directory."; exit 1; }
        download_required=false  # Set flag to false
    fi

    if [ "$download_required" = true ]; then
        LATEST_VERSION=$(curl -s https://api.github.com/repos/t3rn/executor-release/releases/latest | grep 'tag_name' | cut -d\" -f4)
        EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/${LATEST_VERSION}/executor-linux-${LATEST_VERSION}.tar.gz"
        curl -L -o executor-linux-${LATEST_VERSION}.tar.gz $EXECUTOR_URL
        tar -xzvf executor-linux-${LATEST_VERSION}.tar.gz
        #rm -rf executor-linux-${LATEST_VERSION}.tar.gz
    else
        show "Skipping download as the latest version is already present."
    fi

    USERNAME=$(whoami)
    HOME_DIR=$(eval echo ~$USERNAME)

    CONFIG_FILE="$HOME_DIR/executor/executor/bin/.t3rn"
    echo "NODE_ENV=testnet" > $CONFIG_FILE
    echo "LOG_LEVEL=debug" >> $CONFIG_FILE
    echo "LOG_PRETTY=false" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_ORDERS=true" >> $CONFIG_FILE
    echo "EXECUTOR_PROCESS_CLAIMS=true" >> $CONFIG_FILE
    echo "PRIVATE_KEY_LOCAL=" >> $CONFIG_FILE
    echo "ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,optimism-sepolia,l1rn'" >> $CONFIG_FILE
    echo "RPC_ENDPOINTS_BSSP='https://base-sepolia-rpc.publicnode.com'" >> $CONFIG_FILE
    echo -e "${YELLOW}Your private key:${NC}"
    read PRIVATE_KEY
    sed -i "s|PRIVATE_KEY_LOCAL=|PRIVATE_KEY_LOCAL=$PRIVATE_KEY|" $CONFIG_FILE

    sudo bash -c "cat <<EOT > /etc/systemd/system/t3rn.service
[Unit]
Description=t3rn Service
After=network.target

[Service]
EnvironmentFile=$HOME_DIR/executor/executor/bin/.t3rn
ExecStart=$HOME_DIR/executor/executor/bin/executor
WorkingDirectory=$HOME_DIR/executor/executor/bin/
Restart=on-failure
User=$USERNAME

[Install]
WantedBy=multi-user.target
EOT"

    sudo systemctl daemon-reload
    sudo systemctl enable t3rn.service
    sudo systemctl start t3rn.service
    echo
    read -p "Press Enter to return to the main menu..."
}

view_logs() {
    echo -e "${GREEN}📄 Viewing Logs...${RESET}"
    sudo journalctl -u t3rn.service -f -n 50
    echo
    read -p "Press Enter to return to the main menu..."
}

stop_node() {
    echo -e "${YELLOW}⏹️  Stopping Node...${RESET}"
    sudo systemctl stop t3rn.service
    echo -e "${GREEN}Node stopped successfully.${RESET}"
    echo
    read -p "Press Enter to return to the main menu..."
}

start_node() {
    echo -e "${GREEN}▶️  Starting Node...${RESET}"
    sudo systemctl start t3rn.service
    echo -e "${GREEN}Node started successfully.${RESET}"
    echo
    read -p "Press Enter to return to the main menu..."
}

# Main menu loop
while true; do
    show_menu() {
        clear
        print_logo
        echo -e "    ${WHITE}Please choose an option:${RESET}"
        echo
        echo -e "    ${WHITE}1.${RESET} ${ICON_INSTALL} Install/Update Node"
        echo -e "    ${WHITE}2.${RESET} ${ICON_LOGS} View Service Logs"
        echo -e "    ${WHITE}3.${RESET} ${ICON_STOP} Stop Node"
        echo -e "    ${WHITE}4.${RESET} ${ICON_START} Start Node"
        echo -e "    ${WHITE}0.${RESET} ${ICON_EXIT} Exit"
        echo -ne "    ${GREEN}Enter your choice [0-6]:${RESET} "
        read choice
    }

    show_menu

    case $choice in
        1) install_update_node ;;
        2) view_logs ;;
        3) stop_node ;;
        4) start_node ;;
        0) echo -e "${GREEN}❌ Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option. Please try again.${RESET}"; sleep 2 ;;
    esac
done