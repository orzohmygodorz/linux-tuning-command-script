#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./decentralizeProcessesToDifferentHyperthreading.sh --process-name <process_name> [--high-bound <0~100> --duration-time <seconds>]"
    exit 0
fi
processName=""
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--process-name" ]]; then processName=${argArray[($i + 1)]}; fi
done
#processPidArray=()
#if [[ "$processName" == "" ]]; then
#    echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name>"
#    exit 0
#else
#    processPidArray=$( ./../processOp/getPid.sh "$processName" )
#    processPidArray=( $processPidArray )
#    if [[ ${#processPidArray[@]} -eq 0 ]]; then
#        echo "Error Process Name."
#        echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name>"
#        exit 0
#    fi
#    #echo "processPidArray:" ${processPidArray[@]}
#fi
processesPsrsArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getProcessesPsrs.sh))" --process-name "$processName" )
processesPsrsArray=( $processesPsrsArray )
echo ${processesPsrsArray[@]}

#
# Decentralize Processes To Different Hyperthreading
#

decentralize_processes_to_different_hyperthreading() {
    for ((i=0; i<${#processesPsrsArray[@]}; i++)); do
        threadSiblingsList=$(cat /sys/devices/system/cpu/cpu${processesPsrsArray[$i]}/topology/thread_siblings_list)
        if [[${processesPsrsArray[$i]} -eq $(echo $threadSiblingsList | cut -d"," -f1)]]; then
            for ((j=$i; j<${#processesPsrsArray[@]}; j++)); do
                
            done
        else
        fi
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
decentralize_processes_to_different_hyperthreading
clean

