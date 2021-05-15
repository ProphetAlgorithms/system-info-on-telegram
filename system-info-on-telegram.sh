#!/bin/bash

# Use the bot that manages bots, @BotFather !. Contact
# him and you can manage every aspect of your bots,
# such as his token.
# Remember do not reveal it to anyone!
BOT_TOKEN="<your_bot_token>"

# The CHAT_ID can be obtained by visiting a url containing
# the token of your bot.
# If the link does not return anything, write a message
# in the chat and try to visit the link again:
# https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
# I think you shouldn't reveal that either
CHAT_ID=<your_chat_id>

# Calculator function to format numbers correctly
calc() { awk "BEGIN{ printf \"%.2f\n\", $* }"; }

# Tag html for pre-formatted fixed-width code block, TAGOpen, TAGClose.
# Rememeber, to use this tag, pass HTML in the url parse_mode field.
# I use a pair of tags for each section of the message, so that i can
# only copy that section, when clicked, and not the whole message.
TAGO="<pre>"
TAGC="</pre>"

# Date and uptime
DATE=${TAGO}$(date +"%d/%m/%Y - %H:%M:%S")"%0A"${TAGC}
UPTIME=${TAGO}$(echo $(uptime) | sed -e 's/.\+up\(\s[0-9]\+\sday[s]\?\).\+\(load.\+$\)/uptime:\1%0A\2/')"%0A"${TAGC}

# Generic info
GEN_INFO=${TAGO}$(uname -srp)"%0A"${TAGC}

# Logged users
if [ "$(w -h)" = "" ]; then
   LOGIN=""
else
   LOGIN="${TAGO}%0ALOGIN:%0A$(echo "$(w -h)" | sed -E 's/^/- /g')${TAGC}%0A"
fi

# Top 10 processes
PROCESSES="${TAGO}%0APROCESSES:%0A$(ps -Ao user,comm,pcpu,pmem --sort=-pcpu | head -n 6)${TAGC}%0A"

# Memory usage
MEMORY="${TAGO}%0A$(free -h | sed -e 's/\(^\|Mem:\|Swap:\)\s\s\s\(\s\+[0-9a-zA-Z\.]\+\)\s\s\s\(\s\+[0-9a-zA-Z\.]\+\)\s\s\s\(\s\+[0-9a-zA-Z\.]\+\)\(.\+\)\?\(\n\|$\)/\1\2\3\4/g' | sed -e 's/^\s\s\s\s\s\s\s/MEMORY:/')${TAGC}%0A"

# Usage for root mount
DISK="${TAGO}%0ADISK:%0A$(df -h --output=target,used,avail,size /)${TAGC}%0A"

# Network usage, average 10 seconds and total data
RX=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX=$(cat /sys/class/net/eth0/statistics/tx_bytes)
sleep 10
RX2=$(cat /sys/class/net/eth0/statistics/rx_bytes)
TX2=$(cat /sys/class/net/eth0/statistics/tx_bytes)
IN=$(calc \(\(\(\(${RX2}-${RX}\)/10\)/1048576\)*8\))
OUT=$(calc \(\(\(\(${TX2}-${TX}\)/10\)/1048576\)*8\))
ALLIN=$(calc ${RX2} / 1073741824)
ALLOUT=$(calc ${TX2} / 1073741824)
NETWORK="${TAGO}%0ANETWORK eth0 (avg 10s - all):%0A in:  ${IN} Mb/s  -  ${ALLIN} GB%0Aout:  ${OUT} Mb/s  -  ${ALLOUT} GB${TAGC}%0A"

# Tendermint validator info.
# By default it is disabled, yes to enable.
# Warning: do not use the same user to start the script and the validator!
ENABLE_VALIDATOR_INFO="no"
if [ ${ENABLE_VALIDATOR_INFO} = "yes" ]; then
  # Adjust the name according to your needs, this is the name
  # used to find the executables and the repository folder.
  NODE_NAME="<base_name>"
  CLI_BIN="${NODE_NAME}cli"
  USER_BASE_PATH=$(printenv HOME)
  # Adjust the repository name to your needs, it may not reflect the form <node_name> + "d"
  #REPO_NAME="${NODE_NAME}d"
  #BIN_PATH="${USER_BASE_PATH}/${REPO_NAME}/build/"
  SIGNING_INFO_CMD=" query slashing signing-info "
  CHAINID_FLAG=" --chain-id "
  VALCONSPUB_ADDR="<valconspub_address>"
  MONIKER=$(curl localhost:26657/status? 2>&1 | awk '{gsub(/^( )+/,"")}/moniker/{print $0}' | sed -e 's/[",]//g' | sed -e 's/moniker:\s//')
  VALIDATOR_NETWORK=$(curl localhost:26657/status? 2>&1 | awk '{gsub(/^( )+/,"")}/network/{print $0}' | sed -e 's/[",]//g' | sed -e 's/network:\s//')
  VOTING_POWER=$(curl localhost:26657/status? 2>&1 | awk '{gsub(/^( )+/,"")}/voting_power/{print $0}' | sed -e 's/[",]//g' | sed -e 's/voting_power:\s//')
  # Remove this folder every cli call because it increases the content by 8kb per call,
  # frequent use could take up considerable space in the long run.
  rm -rf ${USER_BASE_PATH}"/."${CLI_BIN}"/"
  SIGNING_INFO=$(${CLI_BIN}${SIGNING_INFO_CMD}${VALCONSPUB_ADDR}${CHAINID_FLAG}${VALIDATOR_NETWORK} 2>/dev/null | awk '/jailed_until/;/tombstoned/;/missed_blocks_counter/' | sed -e 's/_/ /g')
  VALIDATOR_INFO="${TAGO}%0AVALIDATOR:%0Amoniker: ${MONIKER}%0Anetwork: ${VALIDATOR_NETWORK}%0Avoting power: ${VOTING_POWER}%0A${SIGNING_INFO}${TAGC}"
else
  VALIDATOR_INFO=""
fi

# Build final message
MESSAGE=${DATE}${GEN_INFO}${UPTIME}${LOGIN}${PROCESSES}${MEMORY}${DISK}${NETWORK}${VALIDATOR_INFO}

# Telegram api url
URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

# Curl command for sending data
/bin/curl -s -d "chat_id=${CHAT_ID}&disable_web_page_preview=1&parse_mode=html&text=${MESSAGE}" ${URL} > /dev/null
