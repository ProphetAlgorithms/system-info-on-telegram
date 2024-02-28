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

# Function to format the number of tokens correctly:
# first param for token's decimals, second param for number of tokens
printTokens() {
  local token_decimals=$1
  local show_decimals=5
  local decimal_sep=","
  local thousands_sep="."
  local n=$(echo $2 | sed -e 's/\([0-9]\+\)\([\.|\,][0-9]*\)\?/\1/')
  local nDiff=$((${#n} - ${token_decimals}))
  if [ "${n}" = "" ]; then
    n=0
  fi
  if [ ${nDiff} -gt 0 ]; then
    local int="$(echo ${n} | sed -e 's/\([0-9]\+\)\?\([0-9]\{'"${token_decimals}"'\}\)/\1/' | rev | sed -e 's/\([0-9][0-9][0-9]\)/\1'"${thousands_sep}"'/g;T' -e 's/\'"${thousands_sep}"'$//' | rev)"
    local dec=$(echo ${n} | sed -e 's/\([0-9]\+\)\?\([0-9]\{'"${token_decimals}"'\}\)/\2/' | sed -e 's/\(\([0-9]\{'"${show_decimals}"'\}\)\([0-9]*\)\)/\2/')
    echo ${int}${decimal_sep}${dec}
  else
    local zDiff=$(echo ${nDiff} | sed -e 's/^-//')
    local zeros=""
    while [ 0 -lt ${zDiff} ]
    do
       zeros=${zeros}$(echo -n "0")
       zDiff=$(( ${zDiff} - 1 ))
    done
    echo 0${decimal_sep}$(echo ${n} | sed -e 's/^/'"${zeros}"'/' |  sed -e 's/\(\(^[0-9]\{'"${show_decimals}"'\}\)\([0-9]*\)\)/\2/')
  fi
}

# Tag html for pre-formatted fixed-width code block, TAGOpen, TAGClose.
# Rememeber, to use this tag, pass HTML in the url parse_mode field.
# I use a pair of tags for each section of the message, so that i can
# only copy that section, when clicked, and not the whole message.
TAGO="<code>"
TAGC="</code>"

# Date and uptime
DATE=${TAGO}$(date +"%d/%m/%Y - %H:%M:%S")"%0A"${TAGC}
UPTIME=${TAGO}$(echo $(uptime) | sed -e 's/.\+up\(\s[0-9:]\+\(\sdays\?\)\?\).\+\(load.\+$\)/uptime:\1%0A\3/')"%0A"${TAGC}

# Generic info
GEN_INFO=${TAGO}$(uname -srp)"%0A"${TAGC}

# Logged users
if [ "$(w -h)" = "" ]; then
  LOGIN=""
else
  LOGIN="${TAGO}%0ALOGIN:%0A$(echo "$(w -h)" | sed -E 's/^/- /g')${TAGC}%0A"
fi

# Top 5 processes
PROCESSES="${TAGO}%0APROCESSES:%0A$(ps -Ao user,comm,pcpu,pmem --sort=-pcpu | head -n 6)${TAGC}%0A"

# Memory usage
MEMORY="${TAGO}%0A$(free -h | sed -e 's/\(^\|Mem:\|Swap:\)\s\s\s\(\s\+[0-9a-zA-Z\.]\+\)\s\s\s\(\s\+[0-9a-zA-Z\.]\+\)\s\s\s\(\s\+[0-9a-zA-Z\.]\+\)\(.\+\)\?\(\n\|$\)/\1\2\3\4/g' | sed -e 's/^\s\s\s\s\s\s\s/MEMORY:/')${TAGC}%0A"

# Usage for root mount
DISK="${TAGO}%0ADISK:%0A$(df -h --output=target,used,avail,size /)${TAGC}%0A"

# Network usage, average 10 seconds and total data
IF="eth0"
RX=$(cat /sys/class/net/${IF}/statistics/rx_bytes)
TX=$(cat /sys/class/net/${IF}/statistics/tx_bytes)
sleep 10
RX2=$(cat /sys/class/net/${IF}/statistics/rx_bytes)
TX2=$(cat /sys/class/net/${IF}/statistics/tx_bytes)
IN=$(calc \(\(\(\(${RX2}-${RX}\)/10\)/1048576\)*8\))
OUT=$(calc \(\(\(\(${TX2}-${TX}\)/10\)/1048576\)*8\))
ALLIN=$(calc ${RX2} / 1073741824)
ALLOUT=$(calc ${TX2} / 1073741824)
NETWORK="${TAGO}%0ANETWORK ${IF} (avg 10s - all):%0A in:  ${IN} Mb/s  -  ${ALLIN} GB%0Aout:  ${OUT} Mb/s  -  ${ALLOUT} GB${TAGC}%0A"

# Tendermint validator info.
# By default it is disabled, yes to enable.
# Use the same user to start the script and the validator.
ENABLE_VALIDATOR_INFO="no"
if [ ${ENABLE_VALIDATOR_INFO} = "yes" ]; then
  # Adjust the name according to your needs, this is the name
  # used to find the executables and the repository folder.
  NODE_NAME="<daemon name without d>"
  CLI_BIN="${NODE_NAME}d"
  USER_BASE_PATH=$(printenv HOME)
  STAKING_VALIDATOR_CMD=" query staking validator "
  SLASHING_SIGNING_CMD=" query slashing signing-info "
  COMMISSION_CMD=" query distribution commission "
  BALANCES_CMD=" query bank balances "
  VERSION_CMD=" version"
  TENDERMINT_RPC_NODE="http://127.0.0.1:26657"
  VALOPER_ADDR="<valoper address>"
  ACCOUNT_ADDR="<account address>"
  STAKING_VALIDATOR_INFO="$(${CLI_BIN}${STAKING_VALIDATOR_CMD}${VALOPER_ADDR})"
  CONSENSUS_PUBKEY="$(echo "${STAKING_VALIDATOR_INFO}" 2>/dev/null | awk '/(^|\s)key/' | sed -e 's/^\s\+\?"\?\(.\+\)"\?:\s"\?\(.\+\)"\?,\?/\2/')"
  CONSENSUS_PUBKEY_PARAM="{\"@type\":\"/cosmos.crypto.ed25519.PubKey\",\"key\":\"${CONSENSUS_PUBKEY}\"}"
  SLASHING_SIGNING_INFO="$(${CLI_BIN}${SLASHING_SIGNING_CMD}${CONSENSUS_PUBKEY_PARAM})"
  COMMISSION_INFO="$(echo $(${CLI_BIN}${COMMISSION_CMD}${VALOPER_ADDR}) | sed -e 's/\^\?[commission:]\+\?\s\-\samount:\s"\([^"]\+\)"\s\denom\:\s\([a-zA-Z0-9]\+\)/\2: \1\n/g' | sed -e '/^$/d')"
  BALANCES_INFO="$(echo $(${CLI_BIN}${BALANCES_CMD}${ACCOUNT_ADDR}) | sed -e 's/\^\?[balances:]\+\?\s\-\samount:\s"\([^"]\+\)"\s\denom\:\s\([a-zA-Z0-9]\+\)/\2: \1\n/g' | sed -e '/^$/d')"
  JAILED="$(echo "${STAKING_VALIDATOR_INFO}" 2>/dev/null | awk '/(^|\s)jailed/' | sed -e 's/^\s\+\?"\?\(.\+\)"\?:\s"\?\(.\+\)"\?,\?/\2/')"
  MISSED_BLOCKS_COUNTER="$(echo "${SLASHING_SIGNING_INFO}" 2>/dev/null | awk '/missed_blocks_counter/{gsub(/_/," ",$1);miss=$0}END{print miss}' | sed -e 's/^\s\+\?"\?\(.\+\)"\?:\s"\(.\+\)",\?/\1: \2/' | sed -e 's/^\s\+\?//')"
  JAILED_UNTIL="$(echo "${SLASHING_SIGNING_INFO}" 2>/dev/null | awk '/jailed_until/{gsub(/_/," ",$1);jail=$0}END{print jail}' | sed -e 's/^\s\+\?"\?\(.\+\)"\?:\s"\(.\+\)",\?/\1: \2/' | sed -e 's/^\s\+\?//')"
  TOMBSTONED="$(echo "${SLASHING_SIGNING_INFO}" 2>/dev/null | awk '/tombstoned/{gsub(/_/," ",$1);tomb=$0}END{print tomb}' | sed -e 's/^\s\+\?"\?\(.\+\)"\?:\s"\(.\+\)",\?/\1: \2/' | sed -e 's/^\s\+\?//')"
  MONIKER_ADDRESS="$(echo "${STAKING_VALIDATOR_INFO}" 2>/dev/null | awk '/moniker/{gsub(/_/," ",$1);mon=$0}/operator_address/{gsub(/_/," ",$1);op_addr=$0}END{print mon"\n"op_addr}' | sed -e 's/^\s\+\?"\?\(.\+\)"\?:\s"\(.\+\)",\?/\1: \2/' | sed -e 's/^\s\+\?//')"
  TOKENS="$(echo "${STAKING_VALIDATOR_INFO}" 2>/dev/null | awk '/tokens/{gsub(/_/," ",$1);tokens=$2}END{print tokens}' | sed -e 's/^\s\+\?"\(.\+\)",\?/\1/')"
  FET_COMMISSION=$(echo "$COMMISSION_INFO" | awk '/afet/{print $2}')
  FET_BALANCE=$(echo "$BALANCES_INFO" | awk '/afet/{print $2}')
  if [ "${JAILED}" = "true" ]; then
    JAILED="${JAILED_UNTIL}"
  else
    JAILED="jailed: ${JAILED}"
  fi
  TOKENS_INFO="bonded tokens: $(echo $(printTokens 18 ${TOKENS}))"
  FET_COMMISSION_INFO="fet commission: "$(printTokens 18 ${FET_COMMISSION})
  FET_BALANCE_INFO="fet balance: "$(printTokens 18 ${FET_BALANCE})
  NODE_STATUS=$(curl ${TENDERMINT_RPC_NODE}/status? 2>&1)
  VALIDATOR_NETWORK=$(echo "${NODE_STATUS}" | awk '/network/' | sed -e 's/^.\+:\s"\(.\+\)",\?/\1/')
  NODE_VERSION=$(echo "node version: ${CLI_BIN} $(${CLI_BIN}${VERSION_CMD})" | sed -r 's/\+/%2B/g')
  # Remove this folder every cli call because it increases the content by 8kb per call,
  # frequent use could take up considerable space in the long run.
  # *** Not needed with the stargate version upgrade because fetchcli was included in the fetchd executable. ***
  # rm -rf ${USER_BASE_PATH}"/."${CLI_BIN}"/"
  VALIDATOR_INFO="${TAGO}%0AVALIDATOR:%0A${NODE_VERSION}%0A${MONIKER_ADDRESS}%0Anetwork: ${VALIDATOR_NETWORK}%0A${TOKENS_INFO}%0A${FET_BALANCE_INFO}%0A${FET_COMMISSION_INFO}%0A${TOMBSTONED}%0A${JAILED}%0A${MISSED_BLOCKS_COUNTER}${TAGC}"
else
  VALIDATOR_INFO=""
fi

# Build final message
MESSAGE=${DATE}${GEN_INFO}${UPTIME}${LOGIN}${PROCESSES}${MEMORY}${DISK}${NETWORK}${VALIDATOR_INFO}

# Telegram api url
URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

# Curl command for sending data
/bin/curl -s -d "chat_id=${CHAT_ID}&disable_web_page_preview=1&parse_mode=html&text=${MESSAGE}" ${URL} > /dev/null
