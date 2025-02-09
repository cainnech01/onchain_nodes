#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
WHITE='\033[37m'
RESET='\033[0m'

ICON_TELEGRAM="🚀"
ICON_INSTALL="🛠️"
ICON_RESTART="🔄"
ICON_CHECK="✅"
ICON_LOG_OP_NODE="📄"
ICON_LOG_EXEC_CLIENT="📄"
ICON_DISABLE="⏹️"
ICON_EXIT="❌"

install_prerequisites() {
    echo -e "${CYAN}sudo apt update${RESET}"
    sudo apt update

    echo -e "${CYAN}sudo apt upgrade -y${RESET}"
    sudo apt upgrade -y

    echo -e "${CYAN}sudo apt autoremove -y${RESET}"
    sudo apt autoremove -y

    echo -e "${CYAN}sudo apt -qy install curl git jq lz4 build-essential screen${RESET}"
    sudo apt -qy install curl git jq lz4 build-essential screen

    echo -e "${BOLD}${CYAN}Checking for Docker installation...${RESET}"
    if ! command -v docker >/dev/null 2>&1; then
        echo -e "${RED}Docker is not installed. Installing Docker...${RESET}"
        sudo apt install docker.io -y
        echo -e "${CYAN}Docker installed successfully.${RESET}"
    else
        echo -e "${CYAN}Docker is already installed.${RESET}"
    fi

    echo -e "${CYAN}docker version${RESET}"
    docker version

    echo -e "${CYAN}sudo apt-get update${RESET}"
    sudo apt-get update

    if ! command -v docker-compose >/dev/null 2>&1; then
        echo -e "${RED}Docker Compose is not installed. Installing Docker Compose...${RESET}"
        sudo curl -L https://github.com/docker/compose/releases/download/$(curl --silent https://api.github.com/repos/docker/compose/releases/latest | jq .name -r)/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
        sudo chmod 755 /usr/bin/docker-compose
        echo -e "${CYAN}Docker Compose installed successfully.${RESET}"
    else
        echo -e "${CYAN}Docker Compose is already installed.${RESET}"
    fi

    echo -e "${CYAN}install docker compose CLI plugin${RESET}"
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose

    echo -e "${CYAN}make plugin executable${RESET}"
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

    echo -e "${CYAN}docker-compose version${RESET}"
    docker-compose version
}

install_node_process1() {
    echo -e "${CYAN}git clone https://github.com/ritual-net/infernet-container-starter${RESET}"
    git clone https://github.com/ritual-net/infernet-container-starter

    docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
    sed -i 's/image: ritualnetwork\/infernet-node:1.3.1/image: ritualnetwork\/infernet-node:1.2.0/' "$docker_yaml"
    echo -e "${BOLD}${CYAN}docker-compose.yaml(the docker version) has been reverted to 1.2.0${RESET}"

    echo -e "${MAGENTA}${BOLD}Enter 'screen -S ritual', then 'cd ~/infernet-container-starter && project=hello-world make deploy-container'${RESET}"
    echo -e "${MAGENTA}${BOLD}You can detach it if everything is fine (Ctrl A + D).${RESET}"
}

install_node_process2() {
    echo -ne "${BOLD}${MAGENTA}Please enter the new RPC URL: ${RESET}"
    read -e rpc_url1

    echo -ne "${BOLD}${MAGENTA}Please enter the new Private Key (prepend 0x): ${RESET}"
    read -e private_key1

    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json

    temp_file=$(mktemp)

    jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
        '.chain.rpc_url = $rpc |
        .chain.wallet.private_key = $priv |
        .chain.trail_head_blocks = 3 |
        .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
        .chain.snapshot_sync.starting_sub_id = 210000 |
        .chain.snapshot_syRESET.sleep = 3 |
        .chain.snapshot_syRESET.batch_size = 9500 |
        .chain.snapshot_syRESET.starting_sub_id = 200000 |
        .chain.snapshot_syRESET.syRESET_period = 30' $json_1 > $temp_file

    mv $temp_file $json_1

    jq --arg rpc "$rpc_url1" --arg priv "$private_key1" \
        '.chain.rpc_url = $rpc |
        .chain.wallet.private_key = $priv |
        .chain.trail_head_blocks = 3 |
        .chain.registry_address = "0x3B1554f346DFe5c482Bb4BA31b880c1C18412170" |
        .chain.snapshot_sync.starting_sub_id = 210000 |
        .chain.snapshot_syRESET.sleep = 3 |
        .chain.snapshot_syRESET.batch_size = 9500 |
        .chain.snapshot_syRESET.starting_sub_id = 200000 |
        .chain.snapshot_syRESET.syRESET_period = 30' $json_2 > $temp_file

    mv $temp_file $json_2
    rm -f $temp_file

    echo -e "${BOLD}${MAGENTA}RPC URL and Private Key have been updated${RESET}"

    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile

    sed -i "s|sender := .*|sender := $private_key1|" "$makefile"
    sed -i "s|RPC_URL := .*|RPC_URL := $rpc_url1|" "$makefile"

    echo -e "${BOLD}${CYAN}Makefile has been updated${RESET}"

    deploy_s_sol=~/infernet-container-starter/projects/hello-world/contracts/script/Deploy.s.sol
    old_registry="0x663F3ad617193148711d28f5334eE4Ed07016602"
    new_registry="0x3B1554f346DFe5c482Bb4BA31b880c1C18412170"

    echo -e "${CYAN}deploy.s.sol edit completed${RESET}"
    sed -i "s|$old_registry|$new_registry|" "$deploy_s_sol"

    docker_yaml=~/infernet-container-starter/deploy/docker-compose.yaml
    sed -i 's/image: ritualnetwork\/infernet-node:1.2.0/image: ritualnetwork\/infernet-node:1.4.0/' "$docker_yaml"
    echo -e "${BOLD}${CYAN}docker-compose.yaml has been updated to 1.4.0${RESET}"

    echo -e "${CYAN}docker compose down${RESET}"
    cd $HOME/infernet-container-starter/deploy
    docker compose down

    echo -e "${CYAN}docker restart hello-world${RESET}"
    docker restart hello-world

    echo -e "${BOLD}${MAGENTA}docker ps${RESET}"
    docker ps

    echo -e "${BOLD}${MAGENTA}Now, enter 'cd ~/infernet-container-starter/deploy && docker compose up' in the terminal${RESET}"
    echo -e "${BOLD}${MAGENTA}After entering the command and seeing a stream of output, do not press any keys. Close the terminal, open a new terminal, and log in to Contabo again.${RESET}"
}

install_node_process3() {
    echo -e "${CYAN}cd $HOME${RESET}"
    cd $HOME

    echo -e "${CYAN}mkdir foundry${RESET}"
    mkdir foundry

    echo -e "${CYAN}cd $HOME/foundry${RESET}"
    cd $HOME/foundry

    echo -e "${CYAN}curl -L https://foundry.paradigm.xyz | bash${RESET}"
    curl -L https://foundry.paradigm.xyz | bash

    export PATH="/root/.foundry/bin:$PATH"

    echo -e "${CYAN}source ~/.bashrc${RESET}"
    source ~/.bashrc

    echo -e "${CYAN}foundryup${RESET}"
    foundryup

    echo -e "${CYAN}cd ~/infernet-container-starter/projects/hello-world/contracts${RESET}"
    cd ~/infernet-container-starter/projects/hello-world/contracts

    echo -e "${CYAN}rm -rf lib${RESET}"
    rm -rf lib

    echo -e "${CYAN}forge install --no-commit foundry-rs/forge-std${RESET}"
    forge install --no-commit foundry-rs/forge-std

    echo -e "${CYAN}forge install --no-commit ritual-net/infernet-sdk${RESET}"
    forge install --no-commit ritual-net/infernet-sdk

    export PATH="/root/.foundry/bin:$PATH"

    echo -e "${CYAN}cd $HOME/infernet-container-starter${RESET}"
    cd $HOME/infernet-container-starter

    echo -e "${CYAN}project=hello-world make deploy-contracts${RESET}"
    project=hello-world make deploy-contracts

    echo -e "${CYAN}Scroll up to check Logs${RESET}"
    echo -ne "${CYAN}Enter the deployed Sayshello value exactly: ${RESET}"
    read -e says_gm

    callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"

    echo -e "${CYAN}/root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol edit${RESET}"
    sed "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath" | sudo tee "$callcontractpath" > /dev/null

    echo -e "${CYAN}project=hello-world make call-contract${RESET}"
    project=hello-world make call-contract

    read -e Check the deployed Sayshello value

    echo -e "${BOLD}${MAGENTA}The Ritual installation is complete. Great job. (Honestly, did you even do anything? I did all the work, lol.)${RESET}"
}

restart_node() {
    echo -e "${CYAN}docker compose down${RESET}"
    cd $HOME/infernet-container-starter/deploy
    docker compose down

    echo -e "${BOLD}${MAGENTA}docker ps${RESET}"
    docker ps

    echo -e "${BOLD}${MAGENTA}Now, enter 'cd ~/infernet-container-starter/deploy && docker compose up' in the terminal${RESET}"
    echo -e "${BOLD}${MAGENTA}After entering the command and seeing a stream of output, do not press any keys. Close the terminal.${RESET}"
}

update_ritual() {
    echo -e "${BOLD}${RED}Starting the Ritual update (10/31).${RESET}"

    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json

    temp_file=$(mktemp)

    jq '.chain.snapshot_syRESET.sleep = 3 |
        .chain.snapshot_syRESET.batch_size = 9500 |
        .chain.snapshot_syRESET.starting_sub_id = 200000 |
        .chain.snapshot_syRESET.syRESET_period = 30' "$json_1" > "$temp_file"
    mv "$temp_file" "$json_1"

    jq '.chain.snapshot_syRESET.sleep = 3 |
        .chain.snapshot_syRESET.batch_size = 9500 |
        .chain.snapshot_syRESET.starting_sub_id = 200000 |
        .chain.snapshot_syRESET.syRESET_period = 30' "$json_2" > "$temp_file"
    mv "$temp_file" "$json_2"

    rm -f $temp_file

    echo -e "${YELLOW}Stopping Docker.${RESET}"
    cd ~/infernet-container-starter/deploy && docker compose down

    echo -e "${YELLOW}Now, enter ${RESET}${RED}'cd ~/infernet-container-starter/deploy && docker compose up'${RESET}${YELLOW} to restart Docker.${RESET}"
}
change_Wallet_Address() {

    echo -ne "${BOLD}${MAGENTA}Please enter the new Private Key (prepend 0x): ${RESET}"
    read -e private_key1

    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/confi
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile 

    temp_file=$(mktemp)

    jq --arg priv "$private_key1" \
        '.chain.wallet.private_key = $priv' $json_1 > $temp_file

    mv $temp_file $json_1

    jq --arg priv "$private_key1" \
        '.chain.wallet.private_key = $priv' $json_2 > $temp_file

    mv $temp_file $json_2

    rm -f $temp_file

    echo -e "${BOLD}${MAGENTA} Private key has been updated ${RESET}"

    sed -i "s|sender := .*|sender := $private_key1|" "$makefile"

    echo -e "${BOLD}${MAGENTA} makefile's Private Key has been updated ${RESET}"

    echo -e "${CYAN}cd $HOME/infernet-container-starter${RESET}"
    cd $HOME/infernet-container-starter

    echo -e "${CYAN}project=hello-world make deploy-contracts${RESET}"
    project=hello-world make deploy-contracts

    echo -e "${CYAN}Scroll up to check Logs${RESET}"
    echo -ne "${CYAN}Enter the deployed Sayshello value exactly: ${RESET}"
    read -e says_gm

    callcontractpath="$HOME/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol"

    echo -e "${CYAN}/root/infernet-container-starter/projects/hello-world/contracts/script/CallContract.s.sol edit${RESET}"
    sed "s|SaysGM saysGm = SaysGM(.*)|SaysGM saysGm = SaysGM($says_gm)|" "$callcontractpath" | sudo tee "$callcontractpath" > /dev/null

    echo -e "${CYAN}project=hello-world make call-contract${RESET}"
    project=hello-world make call-contract

    echo -e "${BOLD}$M{MAGENTA}Wallet address change has been completed.${RESET}"
}

change_RPC_Address() {

    echo -ne "${BOLD}${MAGENTA}Please enter the new RPC URL: ${RESET}"
    read -e rpc_url1

    json_1=~/infernet-container-starter/deploy/config.json
    json_2=~/infernet-container-starter/projects/hello-world/container/config.json
    makefile=~/infernet-container-starter/projects/hello-world/contracts/Makefile 

    temp_file=$(mktemp)

    jq --arg rpc "$rpc_url1" \
        '.chain.rpc_url = $rpc' $json_1 > $temp_file

    mv $temp_file $json_1

    jq --arg rpc "$rpc_url1" \
        '.chain.rpc_url = $rpc' $json_2 > $temp_file

    mv $temp_file $json_2

    rm -f $temp_file

    echo -e "${BOLD}${MAGENTA} RPC URL has been updated ${RESET}"

    sed -i "s|RPC_URL := .*|RPC_URL := $rpc_url1|" "$makefile"

    echo -e "${BOLD}${MAGENTA} makefile's RPC URL has been updated ${RESET}"

    echo -e  "${CYAN}docker restart infernet-anvil${RESET}"
    docker restart infernet-anvil

    echo -e  "${CYAN}docker restart hello-world${RESET}"
    docker restart hello-world

    echo -e  "${CYAN}docker restart infernet-node${RESET}"
    docker restart infernet-node

    echo -e  "${CYAN}docker restart infernet-fluentbit${RESET}"
    docker restart infernet-fluentbit

    echo -e  "${CYAN}docker restart infernet-redis${RESET}"
    docker restart infernet-redis

    echo -e "${BOLD}${MAGENTA} RPC URL update completed. ${RESET}"
    echo -e "${BOLD}${MAGENTA} If the RPC URL update still doesn't work, rerun the command and execute option 4.${RESET}"
}

uninstall_node() {
    echo -e "${BOLD}${CYAN}Remove Ritual dockers...${RESET}"
    docker stop infernet-anvil
    docker stop infernet-node
    docker stop hello-world
    docker stop infernet-redis
    docker stop infernet-fluentbit

    docker rm -f infernet-anvil
    docker rm -f infernet-node
    docker rm -f hello-world
    docker rm -f infernet-redis
    docker rm -f infernet-fluentbit

    cd ~/infernet-container-starter/deploy && docker compose down

    echo -e "${BOLD}${CYAN}Removing ritual docker images...${RESET}"
    docker image ls -a | grep "infernet" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "infernet" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "fluent-bit" | awk '{print $3}' | xargs docker rmi -f
    docker image ls -a | grep "redis" | awk '{print $3}' | xargs docker rmi -f

    echo -e "${CYAN}rm -rf $HOME/foundry${RESET}"
    rm -rf $HOME/foundry

    echo -e "${CYAN}sed -i '/\/root\/.foundry\/bin/d' ~/.bashrc${RESET}"
    sed -i '/\/root\/.foundry\/bin/d' ~/.bashrc

    echo -e "${CYAN}rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib${RESET}"
    rm -rf ~/infernet-container-starter/projects/hello-world/contracts/lib

    echo -e "${CYAN}forge clean${RESET}"
    forge clean

    echo -e "${BOLD}${CYAN}Removing infernet-container-starter directory...${RESET}"
    cd $HOME
    sudo rm -rf infernet-container-starter
    cd $HOME

    echo -e "${BOLD}${CYAN}Files related to the Ritual Node have been deleted. Just in case, I didn't delete the Docker commands because you might have other Docker containers.${RESET}"
}

print_logo() {
    curl https://raw.githubusercontent.com/cainnech01/chain_nodes/refs/heads/main/logo.sh | bash
    echo -e "          ${WHITE}${ICON_TELEGRAM} Follow us on Telegram!${RESET}"
}

# Main menu loop
while true; do
    show_menu() {
        clear
        print_logo
        echo -e "    ${WHITE}Please choose an option:${RESET}"
        echo
        echo -e "    ${WHITE}1.${RESET} ${ICON_INSTALL} Install Node_1"
        echo -e "    ${WHITE}2.${RESET} ${ICON_LOGS} Install Node_2"
        echo -e "    ${WHITE}3.${RESET} ${ICON_WALLET} Install Node_3"
        echo -e "    ${WHITE}4.${RESET} ${ICON_RESTART} Restart Node"
        echo -e "    ${WHITE}5.${RESET} ${ICON_STOP} Change Wallet Address"
        echo -e "    ${WHITE}6.${RESET} ${ICON_START} Change RPC Address"
        echo -e "    ${WHITE}7.${RESET} ${ICON_START} Update Node"
        echo -e "    ${WHITE}8.${RESET} ${ICON_START} DELETE THAT SHIT"
        echo -e "    ${WHITE}9.${RESET} ${ICON_START} Install Prequisites"
        echo -e "    ${WHITE}0.${RESET} ${ICON_EXIT} Exit"
        echo -ne "    ${GREEN}Enter your choice [0-6]:${RESET} "
        read choice
    }

    show_menu

    case $choice in
        1) install_node_process1 ;;
        2) install_node_process2;;
        3) install_node_process3 ;;
        4) restart_node ;;
        5) change_Wallet_Address ;;
        6) change_RPC_Address ;;
        7) update_ritual ;;
        8) uninstall_node ;;
        9) install_prerequisites ;;
        0) echo -e "${GREEN}❌ Exiting...${RESET}"; exit 0 ;;
        *) echo -e "${RED}❌ Invalid option. Please try again.${RESET}"; sleep 2 ;;
    esac
done