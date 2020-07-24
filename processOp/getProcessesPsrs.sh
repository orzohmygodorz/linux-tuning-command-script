#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./getProcessesPsrs.sh --process-name <processName>"
    exit 0
fi
processName=""
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--process-name" ]]; then processName=${argArray[($i + 1)]}; fi
done
processPidArray=()
if [[ "$processName" == "" ]]; then
    echo "Usage: ./getProcessesPsrs.sh --process-name <processName>"
    exit 0
else
    processPidArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getPid.sh))" "$processName" )
    processPidArray=( $processPidArray )
    if [[ ${#processPidArray[@]} -eq 0 ]]; then
        echo "Error Process Name."
        echo "Usage: ./getProcessesPsrs.sh --process-name <processName>"
        exit 0
    fi
fi

processesPsrsArray=()
get_processes_psrs() {
    for ((i=0; i<${#processPidArray[@]}; i++)); do
        #mapfile -t psArray < <( ps -o psr $pid | grep -o '[[:digit:]]' )
        processesPsrsArray+=( $( ps -o psr ${processPidArray[$i]} | sed -n '2 p') )
        #unset psArray
    done
}

#
# clean
#
clean() {
    unset processesPsrsArray
    unset processPidArray
    unset processName
    unset argArray
}

#
# main function
#
get_processes_psrs
echo ${processesPsrsArray[@]}
clean
