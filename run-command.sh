#!/usr/bin/env bash

set -e

ME=$(basename "$0")
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

DATA_FILE="${DIR}/output.json"
HOST_IP_FILE="${DIR}/ips"
declare -a DEFAULT_FILTERS=('Name=instance-state-name,Values=running')
declare -a REQUIRED_TOOLS=('dsh' 'jq')

logOut() {
  echo -e "[${ME}] $(date +%Y-%m-%dT%H:%M:%S%z) | ${1}"
}

failErrOut() {
  echo "[${ME}] $(date +%Y-%m-%dT%H:%M:%S%z) | ERROR - ${1} ! Exiting ..." >&2
  exit 1
}

printHelp() {
  echo "Usage: ${ME} [-l dsh_fork_limit] -f '<filter 1>' -f '<filter 2>' ... -c '<command>'" >&2
  echo
  echo "   -l dsh_fork_limit      If not set, command is executed on one node at a time."
  echo "   -f filter              One or more aws describe-instance filters. https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html#options"
  echo "   -c command             Command that is executed on the nodes."
  echo
  echo "   Example:"
  echo "   ./${ME} -l 2 -f 'Name=tag:Environment,Values=loadtest' -f 'Name=tag:Cluster,Values=dash,id,exp' -c 'echo Test'"
  echo
}

checkInput() {
  local regexp_str="^Name=[a-zA-Z0-9.\-\:]+,Values=[a-zA-Z0-9.\-]+(,[a-zA-Z0-9.\-]+)*$"
  for tool in "${REQUIRED_TOOLS[@]}"; do
    command -v $tool >/dev/null 2>&1 || failErrOut "'${tool}' is not installed ..."
  done
  [[ -z $CMD ]] && failErrOut "Command must be set using '-c' option"
  [[ -z $FILTERS ]] && failErrOut "Filters must be set using '-f' option"
  for filter in "${FILTERS[@]}"; do
    [[ ! $filter =~ $regexp_str ]] && failErrOut "Filter '${filter}' is wrong"
  done
  return 0
}

prepareExecution() {
  aws ec2 describe-instances --filters $(echo ${DEFAULT_FILTERS[@]}) $(echo ${FILTERS[@]}) --query 'Reservations[].Instances[].{PrivateIpAddress:PrivateIpAddress,Name:Tags[?Key==`Name`].Value}' --output json > $DATA_FILE
  if [[ "$(cat $DATA_FILE)" = "[]" ]]; then
    logOut "No instance found. Exiting ..."
    exit 0
  fi
  logOut "Execute '${CMD}' on the following nodes:\n\n$(cat $DATA_FILE | jq '.[] | "\(.Name) \(.PrivateIpAddress)"' | sed 's/"//g')\n"
  read -p "Continue (y/n)? " choice
  echo
  case "$choice" in
    y|Y ) logOut "Executing ...\n" && cat $DATA_FILE | jq '.[].PrivateIpAddress' | sed 's/"//g' > $HOST_IP_FILE;;
    n|N ) doCleanup && logOut "Exiting ..." && exit 0 ;;
    * ) failErrOut "Invalid choice '${choice}'" ;;
  esac
}

runCommand() {
  if [[ -z $DSH_FORK_LIMIT ]]; then
    dsh_opts="-M"
  else
    dsh_opts="-F ${DSH_FORK_LIMIT} -c -M"
  fi
  dsh $dsh_opts -f $HOST_IP_FILE $CMD
}

doCleanup() {
  rm -f $DATA_FILE $HOST_IP_FILE 2>/dev/null
}

while getopts ":h?f:l:c:" opt; do
  case $opt in
    h)
      printHelp
      exit 0 ;;
    f) FILTERS+=("$OPTARG") ;;
    c) CMD=$OPTARG ;;
    l) DSH_FORK_LIMIT=$OPTARG ;;
    :)
      failErrOut "Option '${OPTARG}' requires an argument"
      ;;
  esac
done
if [ $OPTIND -eq 1 ]; then
  printHelp
  exit 0
fi
shift $((OPTIND -1))

checkInput
prepareExecution
runCommand
doCleanup

logOut ""
logOut "Done"
