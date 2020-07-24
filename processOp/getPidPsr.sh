#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./getPidPsr.sh --pid <pid>"
    exit 0
fi
pid=""
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--pid" ]]; then pid=${argArray[($i + 1)]}; fi
done
if [[ "$pid" == "" ]]; then
    echo "Usage: ./getPidPsr.sh --pid <pid>"
    exit 0
elif ! [ -n "$(ps -p $pid -o pid=)" ]; then
    echo "The Pid is not exist."
    echo "Usage: ./getPidPsr.sh --pid <pid>"
    exit 0
fi

#
# Get Pid's Psr
#
pidPsr=""
get_pid_psr() {
    pidPsr=$( ps -o psr $pid | sed -n '2 p' )
}

#
# clean
#
clean() {
    unset pidPsr
    unset pid
    unset argArray
}

#
# main function
#
get_pid_psr
echo $pidPsr
clean

