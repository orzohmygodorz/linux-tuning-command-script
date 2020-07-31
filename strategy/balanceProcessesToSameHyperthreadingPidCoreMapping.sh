#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./decentralizeProcessesToDifferentHyperthreading.sh --process-name <process_name> [--high-bound <0~100> --duration-time <seconds>]"
    exit 0
fi
analysisResult=()
processName=""
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--analysis-result" ]]; then
        iIndex=1
        while [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "--" ] && [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "" ]; do
            analysisResult+=( ${argArray[$((i + iIndex))]} )
            ((iIndex++))
        done
        unset iIndex
        #echo ${#analysisResult[@]} ${analysisResult[@]}
    fi
    if [[ ${argArray[$i]} == "--process-name" ]]; then processName=${argArray[($i + 1)]}; fi
done
processPidArray=()
if [[ "$processName" == "" ]]; then
    echo "Error Process Name is Empty."
    echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name>"
    exit 0
else
    processPidArray=$( ./../processOp/getPid.sh "$processName" )
    processPidArray=( $processPidArray )
    if [[ ${#processPidArray[@]} -eq 0 ]]; then
        echo "Error Process Name."
        echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name>"
        exit 0
    fi
    #echo "processPidArray:" ${processPidArray[@]}
fi

#
# System Parameters
#
source "$(realpath --relative-to="$PWD" $(find / -name cpuParameters.sh))"

processesPsrsArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getProcessesPsrs.sh))" --process-name "$processName" )
processesPsrsArray=( $processesPsrsArray )
#echo "processesPsrsArray:" ${processesPsrsArray[@]}

#
# Decentralize Processes To Different Hyperthreading
#
countProcessesOnPerCoreArray=()
for ((i=0; i<$coresTotal; i++)); do countProcessesOnPerCoreArray[$i]=0; done
count_processes_on_per_core() {
    for ((i=0; i<${#processesPsrsArray[@]}; i++)); do
        (( countProcessesOnPerCoreArray[${processesPsrsArray[$i]}]+=1 ))
    done
    #echo "original_countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
    #echo "original_processesPsrsArray:" ${processesPsrsArray[@]}
}
balanceProcessesToSameHyperthreadingPidCoreMappingArray=()
balance_processes_to_same_hyperthreading_pid_core_mapping() {
    for ((i=0; i<${#processesPsrsArray[@]}; i++)); do
        threadSiblingsList=$(cat /sys/devices/system/cpu/cpu${processesPsrsArray[$i]}/topology/thread_siblings_list) # eg. {0,12}
        hyperthreadingFirst=$(echo $threadSiblingsList | cut -d"," -f1)
        hyperthreadingSecond=$(echo $threadSiblingsList | cut -d"," -f2)
        if [ ${processesPsrsArray[$i]} -eq $hyperthreadingFirst ] && \
           [ $(( countProcessesOnPerCoreArray[${processesPsrsArray[$i]}] - countProcessesOnPerCoreArray[$hyperthreadingSecond] )) -gt "1" ]; then
            (( countProcessesOnPerCoreArray[ "${processesPsrsArray[$i]}" ]-- ))
            (( countProcessesOnPerCoreArray[ "$hyperthreadingSecond" ]++ ))
            processesPsrsArray[$i]=$hyperthreadingSecond
            #echo "countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
            #echo "processesPsrsArray:" ${processesPsrsArray[@]}
            balanceProcessesToSameHyperthreadingPidCoreMappingArray+=( ${processPidArray[$i]} )
            balanceProcessesToSameHyperthreadingPidCoreMappingArray+=( ${processesPsrsArray[$i]} )
            #echo "balanceProcessesToSameHyperthreadingPidCoreMappingArray:" ${balanceProcessesToSameHyperthreadingPidCoreMappingArray[@]}
        elif [ ${processesPsrsArray[$i]} -eq $(echo $threadSiblingsList | cut -d"," -f2) ] && \
             [ $(( countProcessesOnPerCoreArray[${processesPsrsArray[$i]}] - countProcessesOnPerCoreArray[$hyperthreadingFirst] )) -gt "1" ]; then
            (( countProcessesOnPerCoreArray[${processesPsrsArray[$i]}]-- ))
            (( countProcessesOnPerCoreArray[$hyperthreadingFirst]++ ))
            processesPsrsArray[$i]=$hyperthreadingFirst
            #echo "countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
            #echo "processesPsrsArray:" ${processesPsrsArray[@]}
            balanceProcessesToSameHyperthreadingPidCoreMappingArray+=( ${processPidArray[$i]} )
            balanceProcessesToSameHyperthreadingPidCoreMappingArray+=( ${processesPsrsArray[$i]} )
            #echo "balanceProcessesToSameHyperthreadingPidCoreMappingArray:" ${balanceProcessesToSameHyperthreadingPidCoreMappingArray[@]}
        fi
        unset threadSiblingsList hyperthreadingFirst hyperthreadingSecond
    done
}

#
# clean
#
clean() {
    unset balanceProcessesToSameHyperthreadingPidCoreMappingArray
    unset countProcessesOnPerCoreArray
    unset processesPsrsArray
    unset processPidArray
    unset processName
    unset argArray
}

#
# main function
#
count_processes_on_per_core
balance_processes_to_same_hyperthreading_pid_core_mapping
echo ${balanceProcessesToSameHyperthreadingPidCoreMappingArray[@]}
clean

