#
# Parse the command line arguments
#
argArray=("$@")
if [[ "${#argArray[@]}" == "0" ]]; then
    echo "Usage: ./getPsr.sh <process_name>"
    exit 0
fi
process_name=${argArray[0]}
unset argArray

daemonPidArray=$( ./getPid.sh "$process_name" )
daemonPidArray=( $daemonPidArray )
daemonPsrArray=()
list_daemon_psr() {
    for ((i=0; i<${#daemonPidArray[@]}; i++)); do
        #mapfile -t psArray < <( ps -o psr $pid | grep -o '[[:digit:]]' )
        daemonPsrArray+=( $( ps -o psr ${daemonPidArray[$i]} | sed -n '2 p') )
        #unset psArray
    done
}

#
# clean
#
clean() {
    unset daemonPidArray daemonPsrArray
    unset process_name
}

list_daemon_psr
echo ${daemonPsrArray[@]}
clean
