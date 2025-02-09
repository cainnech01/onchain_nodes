#!/bin/bash

temp_file=$(mktemp)

json_1=~/infernet-container-starter/deploy/config.json
json_2=~/infernet-container-starter/projects/hello-world/container/config.json

jq  '.chain.snapshot_sync.starting_sub_id = 210000' $json_1 > $temp_file

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

