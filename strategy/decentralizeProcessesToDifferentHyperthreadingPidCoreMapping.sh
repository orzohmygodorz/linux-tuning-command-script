#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./decentralizeProcessesToDifferentHyperthreading.sh --process-name <process_name> [--pid-list <pid_list> --high-bound <0~100> --duration-time <seconds>]"
    exit 0
fi
processName=""
processPidArray=()
processesPsrsArray=()
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--pid-list" ]]; then
        iIndex=1
        while [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "--" ] && [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "" ]; do
            processPidArray+=( ${argArray[$((i + iIndex))]} )
            ((iIndex++))
        done
        unset iIndex
        #echo ${#analysisResult[@]} ${analysisResult[@]}
    fi
    if [[ ${argArray[$i]} == "--process-name" ]]; then processName=${argArray[($i + 1)]}; fi
done

#
# Check if input process is not exist
#
if [ "$processName" == "" ] && [ -z $processPidArray ]; then
    echo "Error Process Name is Empty."
    echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name>"
    exit 0
elif [ "$processName" != "" ]; then
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

#
# Perpare the background information: processesPsrsArray=()
#

processesPsrsArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getProcessesPsrs.sh))" --process-name "$processName" )
processesPsrsArray=( $processesPsrsArray )
#echo "processesPsrsArray:" ${processesPsrsArray[@]}

#
# Decentralize Processes To Different Hyperthreading
#
countProcessesOnPerCoreArray=()
for ((i=0; i<$coresTotal; i++)); do countProcessesOnPerCoreArray[$i]=0; done
countProcessesOnPerHyperthreadingArray=()
for ((i=0; i<$coresTotal; i++)); do countProcessesOnPerHyperthreadingArray[$i]=-1; done
for ((i=0; i<$numaNodesTotal; i++)); do
    coreNumaFirst=$( lscpu | grep "NUMA node${i} CPU(s):" | awk '{print $NF}' | cut -d"," -f1 ) # [0-5]
    for ((j=$( echo $coreNumaFirst | cut -d"-" -f1 ); j<=$( echo $coreNumaFirst | cut -d"-" -f2 ); j++)); do
        countProcessesOnPerHyperthreadingArray[$j]=0
    done
    unset coreNumaFirst
done
#echo "countProcessesOnPerHyperthreadingArray:" ${countProcessesOnPerHyperthreadingArray[@]}
count_processes_on_same_hyperthreading() {
    for ((i=0; i<${#processesPsrsArray[@]}; i++)); do # eg. [core8, core9, core10]
        for ((j=0; j<$numaNodesTotal; j++)); do # eg. [node0, node1]
            coreNumaFirst=$( lscpu | grep "NUMA node${j} CPU(s):" | awk '{print $NF}' | cut -d"," -f1 ) # [0-5]
            for ((k=$( echo $coreNumaFirst | cut -d"-" -f1 ); k<=$( echo $coreNumaFirst | cut -d"-" -f2 ); k++)); do # [0,1,2,3,4,5]
                threadSiblingsList=$(cat /sys/devices/system/cpu/cpu$k/topology/thread_siblings_list) # eg. [0,12], [1,13]...
                hyperthreadingFirst=$(echo $threadSiblingsList | cut -d"," -f1)
                hyperthreadingSecond=$(echo $threadSiblingsList | cut -d"," -f2)
                if [ ${processesPsrsArray[$i]} -eq $hyperthreadingFirst ] || \
                   [ ${processesPsrsArray[$i]} -eq $hyperthreadingSecond ]; then
                    (( countProcessesOnPerHyperthreadingArray[$hyperthreadingFirst]+=1 ))
                    (( countProcessesOnPerCoreArray[${processesPsrsArray[$i]}]++ ))
                    #echo "---countProcessesOnPerHyperthreadingArray:" ${countProcessesOnPerHyperthreadingArray[@]}
                    unset threadSiblingsList hyperthreadingFirst hyperthreadingSecond
                    break
                fi
            done
            unset coreNumaFirst
        done
    done
    #echo "original_countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
    #echo "original_processesPsrsArray:" ${processesPsrsArray[@]}
}
#echo "countProcessesOnPerHyperthreadingArray:" ${countProcessesOnPerHyperthreadingArray[@]}

# Count the number of processes per hyperthreading
averageProcessesPerHyperthreadingPerNumaArray=()
average_processes_per_hyperthreading() {
    for ((i=0; i<$numaNodesTotal; i++)); do # eg. [node0, node1]
        averageProcessesPerHyperthreading=0
        coreNumaFirst=$( lscpu | grep "NUMA node${i} CPU(s):" | awk '{print $NF}' | cut -d"," -f1 ) # [0-5]
        for ((j=$( echo $coreNumaFirst | cut -d"-" -f1 ); j<=$( echo $coreNumaFirst | cut -d"-" -f2 ); j++)); do # [0,1,2,3,4,5]
            (( averageProcessesPerHyperthreading += ${countProcessesOnPerHyperthreadingArray[$j]} ))
        done
        #echo "NUMA" $i "averageProcessesPerHyperthreadin:" $averageProcessesPerHyperthreading
        if [[ $(( averageProcessesPerHyperthreading % coresPerSocket )) -eq "0" ]]; then
            averageProcessesPerHyperthreading=$(( $averageProcessesPerHyperthreading / ( $( echo $coreNumaFirst | cut -d"-" -f2 ) - $( echo $coreNumaFirst | cut -d"-" -f1 ) + 1 ) ))
        else
            averageProcessesPerHyperthreading=$(( $averageProcessesPerHyperthreading / ( $( echo $coreNumaFirst | cut -d"-" -f2 ) - $( echo $coreNumaFirst | cut -d"-" -f1 ) + 1) + 1 ))
        fi
        averageProcessesPerHyperthreadingPerNumaArray+=( $averageProcessesPerHyperthreading )
        #echo "averageProcessesPerHyperthreading:" $averageProcessesPerHyperthreading
        unset coreNumaFirst averageProcessesPerHyperthreading
    done
}
decentralizeProcessesToDifferentHyperthreadingPidCoreMapping=()
decentralize_processes_to_different_hyperthreading_pid_core_mapping() {
    # Go through the processes' psr
    for ((i=0; i<${#processesPsrsArray[@]}; i++)); do # eg. [core8, core9, core10]
        for ((j=0; j<$numaNodesTotal; j++)); do # eg. [node0, node1]
            coreNumaFirst=$( lscpu | grep "NUMA node${j} CPU(s):" | awk '{print $NF}' | cut -d"," -f1 ) # [0-5]
            for ((k=$( echo $coreNumaFirst | cut -d"-" -f1 ); k<=$( echo $coreNumaFirst | cut -d"-" -f2 ); k++)); do # [0,1,2,3,4,5]

                threadSiblingsList=$(cat /sys/devices/system/cpu/cpu$k/topology/thread_siblings_list) # eg. [8,20], [9,21]...
                hyperthreadingFirst=$(echo $threadSiblingsList | cut -d"," -f1)
                hyperthreadingSecond=$(echo $threadSiblingsList | cut -d"," -f2)

                # Find the #hyperthreading which higher to averageProcessesPerHyperthreadingPerNuma
                if [[ ( ${processesPsrsArray[$i]} -eq $hyperthreadingFirst || ${processesPsrsArray[$i]} -eq $hyperthreadingSecond ) && \
                   ( ${countProcessesOnPerHyperthreadingArray[$hyperthreadingFirst]} -gt ${averageProcessesPerHyperthreadingPerNumaArray[$j]} ) ]]; then
                    #echo "======numaNodesTotal(j):" $j
                    #echo "countProcessesOnPerHyperthreadingArray, averageProcessesPerHyperthreadingPerNumaArray" \
                    #      ${countProcessesOnPerHyperthreadingArray[${processesPsrsArray[$i]}]} ${averageProcessesPerHyperthreadingPerNumaArray[$j]} \
                    #      "Pid:" ${processPidArray[$i]} "on core" ${processesPsrsArray[$i]}

                    # Go through the same NUMA, to find the #hyperthreading which lower to averageProcessesPerHyperthreadingPerNuma
                    for ((l=$( echo $coreNumaFirst | cut -d"-" -f1 ); l<=$( echo $coreNumaFirst | cut -d"-" -f2 ); l++)); do # [0,1,2,3,4,5]
                        # Find the #hyperthreading which lower to averageProcessesPerHyperthreadingPerNuma
                        if [[ ${countProcessesOnPerHyperthreadingArray[$l]} -lt  ${averageProcessesPerHyperthreadingPerNumaArray[$j]} ]]; then
                            #echo "(hyperthreadingFirst,hyperthreadingSecond)=" $hyperthreadingFirst "," $hyperthreadingSecond
                            #
                            # Target PID
                            #
                            # Find both cores which is in same hyperthreadingFirst with the target PID
                            if [[ ${countProcessesOnPerCoreArray[$hyperthreadingFirst]} -gt \
                                  ${countProcessesOnPerCoreArray[$hyperthreadingSecond]} ]]; then
                                #echo "countProcessesOnPerCoreArray of hyperthreadingFirst > hyperthreadingSecond:" \
                                #     ${countProcessesOnPerCoreArray[$hyperthreadingFirst]} ">" ${countProcessesOnPerCoreArray[$hyperthreadingSecond]}
                                if [[ ${processesPsrsArray[$i]} -ne $hyperthreadingFirst ]]; then 
                                    for ((m=0; m<${#processPidArray[@]}; m++)); do
                                        if [[ ${processesPsrsArray[$m]} -eq $hyperthreadingFirst ]]; then
                                            decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( ${processPidArray[$m]} )
                                            break
                                        fi
                                    done
                                else
                                    decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( ${processPidArray[$i]} )
                                fi
                                #echo "countProcessesOnPerHyperthreadingArray of hyperthreadingFirst-- hyperthreadingSecond++" \
                                #     ${countProcessesOnPerHyperthreadingArray[$hyperthreadingFirst]} \
                                #     ${countProcessesOnPerHyperthreadingArray[$hyperthreadingSecond]}
                            elif [[ ${countProcessesOnPerCoreArray[$hyperthreadingSecond]} -gt \
                                    ${countProcessesOnPerCoreArray[$hyperthreadingFirst]} ]]; then
                                #echo "countProcessesOnPerCoreArray of hyperthreadingSecond > hyperthreadingFirst:" \
                                #     ${countProcessesOnPerCoreArray[$hyperthreadingSecond]} ">" ${countProcessesOnPerCoreArray[$hyperthreadingFirst]}
                                if [[ ${processesPsrsArray[$i]} -ne $hyperthreadingSecond ]]; then
                                    for ((m=0; m<${#processPidArray[@]}; m++)); do
                                        if [[ ${processesPsrsArray[$m]} -eq $hyperthreadingSecond ]]; then
                                            decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( ${processPidArray[$m]} )
                                            break
                                        fi
                                    done
                                else
                                    decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( ${processPidArray[$i]} )
                                fi
                                #echo "countProcessesOnPerHyperthreadingArray of hyperthreadingFirst++ hyperthreadingSecond--" \
                                #     ${countProcessesOnPerHyperthreadingArray[$hyperthreadingFirst]} \
                                #     ${countProcessesOnPerHyperthreadingArray[$hyperthreadingSecond]}
                            else
                                decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( ${processPidArray[$i]} )
                            fi
                            (( countProcessesOnPerHyperthreadingArray[$hyperthreadingFirst]-- ))
                            (( countProcessesOnPerHyperthreadingArray[$l]++ ))

                            #echo "***coreNumaFirst:" $coreNumaFirst
                            #echo "---Modify countProcessesOnPerHyperthreadingArray:" ${countProcessesOnPerHyperthreadingArray[@]} "l:" $l
                            lowCoreThreadSiblingsList=$(cat /sys/devices/system/cpu/cpu$l/topology/thread_siblings_list) # eg. [8,20], [9,21]...
                            lowCoreHyperthreadingFirst=$(echo $lowCoreThreadSiblingsList | cut -d"," -f1)
                            lowCoreHyperthreadingSecond=$(echo $lowCoreThreadSiblingsList | cut -d"," -f2)

                            #
                            # Algorithm
                            #
                            # Find both cores which has less #processes in the same hyperthreading
                            if [[ ${countProcessesOnPerCoreArray[$lowCoreHyperthreadingFirst]} -le \
                                  ${countProcessesOnPerCoreArray[$lowCoreHyperthreadingSecond]} ]]; then # eg. #process in core8 < #process in core20
                                decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( $lowCoreHyperthreadingFirst )
                                #echo "countProcessesOnPerCoreArray of lowCoreHyperthreadingFirst <= lowCoreHyperthreadingSecond" \
                                #     "[" $lowCoreHyperthreadingFirst "]" ${countProcessesOnPerCoreArray[$lowCoreHyperthreadingFirst]} \
                                #     "<= [" $lowCoreHyperthreadingSecond "]" ${countProcessesOnPerCoreArray[$lowCoreHyperthreadingSecond]}
                                # New core location
                                (( countProcessesOnPerCoreArray[$lowCoreHyperthreadingFirst]++ ))
                                # Target PID core location
                                if [[ ${countProcessesOnPerCoreArray[$hyperthreadingFirst]} -ge \
                                      ${countProcessesOnPerCoreArray[$hyperthreadingSecond]} ]]; then
                                    #echo "[" $hyperthreadingFirst "] = " ${countProcessesOnPerCoreArray[$hyperthreadingFirst]} ">=" \
                                    #     "[" $hyperthreadingSecond "] = " ${countProcessesOnPerCoreArray[$hyperthreadingSecond]}
                                    (( countProcessesOnPerCoreArray[$hyperthreadingFirst]-- ))
                                else
                                    #echo "[" $hyperthreadingFirst} "] = " ${countProcessesOnPerCoreArray[$hyperthreadingFirst]} "<" \
                                    #     "[" $hyperthreadingSecond "] = " ${countProcessesOnPerCoreArray[$hyperthreadingSecond]}
                                    (( countProcessesOnPerCoreArray[$hyperthreadingSecond]-- ))
                                fi
                                #echo "---Modify countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]} "l:" $l
                                #echo "Move to new core:" $lowCoreHyperthreadingFirst
                                #echo "Modify countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
                                break
                            else # eg. #process in core8 > #process in core20
                                decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( $lowCoreHyperthreadingSecond )
                                #echo "countProcessesOnPerCoreArray of lowCoreHyperthreadingFirst > lowCoreHyperthreadingSecond" \
                                #     "[" $lowCoreHyperthreadingFirst "]" ${countProcessesOnPerCoreArray[$lowCoreHyperthreadingFirst]}\
                                #     "> [" $lowCoreHyperthreadingSecond "]" ${countProcessesOnPerCoreArray[$lowCoreHyperthreadingSecond]}

                                # New core location
                                (( countProcessesOnPerCoreArray[$lowCoreHyperthreadingSecond]++ ))
                                if [[ ${countProcessesOnPerCoreArray[${processesPsrsArray[$i]}]} -ge \
                                      ${countProcessesOnPerCoreArray[$hyperthreadingSecond]} ]]; then
                                    (( countProcessesOnPerCoreArray[${processesPsrsArray[$i]}]-- ))
                                else
                                    (( countProcessesOnPerCoreArray[$hyperthreadingSecond]-- ))
                                fi
                                #echo "Move to new core:" $lowCoreHyperthreadingSecond
                                #echo "Modify countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
                                break
                            fi
                            
                        fi
                    done
                    #decentralizeProcessesToDifferentHyperthreadingPidCoreMapping+=( ${processPidArray[$i]} )
                    break
                fi

            done
            unset coreNumaFirst
        done
    done
    echo
    #echo "decentralizeProcessesToDifferentHyperthreadingPidCoreMapping:" ${decentralizeProcessesToDifferentHyperthreadingPidCoreMapping[@]}
    #echo "#decentralizeProcessesToDifferentHyperthreadingPidCoreMapping:" ${#decentralizeProcessesToDifferentHyperthreadingPidCoreMapping[@]}
}

#
# clean
#
clean() {
    unset decentralizeProcessesToDifferentHyperthreadingPidCoreMapping
    unset countProcessesOnPerCoreArray
    unset processesPsrsArray
    unset processPidArray
    unset processName
    unset argArray
}

#
# main function
#
count_processes_on_same_hyperthreading
#echo "countProcessesOnPerHyperthreadingArray:" ${countProcessesOnPerHyperthreadingArray[@]}
#echo "countProcessesOnPerCoreArray:" ${countProcessesOnPerCoreArray[@]}
average_processes_per_hyperthreading
#echo "averageProcessesPerHyperthreadingPerNumaArray:" ${averageProcessesPerHyperthreadingPerNumaArray[@]}
decentralize_processes_to_different_hyperthreading_pid_core_mapping
echo ${decentralizeProcessesToDifferentHyperthreadingPidCoreMapping[@]}
clean

