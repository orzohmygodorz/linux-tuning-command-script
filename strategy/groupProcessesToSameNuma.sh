#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name> [--high-bound <0~100> --duration-time <seconds>]"
    exit 0
fi
processName=""
highBound=90
durationTime=5
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--process-name" ]]; then processName=${argArray[($i + 1)]}; fi
    if [[ ${argArray[$i]} == "--high-bound" ]]; then highBound=${argArray[($i + 1)]}; fi
    if [[ ${argArray[$i]} == "--duration-time" ]]; then durationTime=${argArray[($i + 1)]}; fi
done
processPidArray=()
if [[ "$processName" == "" ]]; then
    echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name> [--high-bound <0~100>]"
    exit 0
else
    processPidArray=$( ./../processOp/getPid.sh "$processName" )
    processPidArray=( $processPidArray )
    if [[ ${#processPidArray[@]} -eq 0 ]]; then
        echo "Error Process Name."
        echo "Usage: ./groupProcessesToSameNuma.sh --process-name <process_name> [--high-bound <0~100>]"
        exit 0
    fi
    #echo "processPidArray:" ${processPidArray[@]}
fi

coresTotal=$( cat /proc/cpuinfo | grep processor | wc -l )
threadsPerCore=$( lscpu | grep 'Thread(s) per core:' | awk '{print $NF}' )
coresPerSocket=$( lscpu | grep 'Core(s) per socket:' | awk '{print $NF}' )
numaNodesTotal=$( lscpu | grep 'NUMA node(s):' | awk '{print $NF}' )

#
# Get the Average Utilization Per Core Array (0.00~100.00)
#
#checkIfCpuUtilizationOverHighboundArray=()
#mapfile -t averageUtilizationPerCoreArray < <( ./../tools/mpstat/averageCpuUtilizationPerCore.sh 1 $durationTime -P ALL )
#averageUtilizationPerCoreArray=( $averageUtilizationPerCoreArray )
#echo $averageUtilizationPerCoreArray
#for ((i=0; i<${#averageUtilizationPerCoreArray[@]}; i++)); do
#    if [[ ${averageUtilizationPerCoreArray[$i]} > $highBound ]]; then
#        checkIfCpuUtilizationOverHighboundArray+=( "true" )
#    else
#        checkIfCpuUtilizationOverHighboundArray+=( "false" )
#    fi
#done
#unset averageUtilizationPerCoreArray
#echo $checkIfCpuUtilizationOverHighboundArray

#
# Get the Check If Cpu Utilization Over Highbound Array (True/False)
#
mapfile -t checkIfCpuUtilizationOverHighboundArray < <( bash "$(realpath --relative-to="$PWD" $(find / -name checkIfCpuUtilizationOverHighbound.sh))" --high-bound $highBound )
checkIfCpuUtilizationOverHighboundArray=( $checkIfCpuUtilizationOverHighboundArray )
#echo ${checkIfCpuUtilizationOverHighboundArray[@]}

#
# Group Processes To Same Numa Core Array
#
# Find Cpu Utilization Over Highbound Cores Total, eg. (OverHighboundCoresInNode0, OverHighboundCoresInNode1)=(1,2)
busyCoreTotalArray=()
cpu_utilization_over_highbound_cores_total() {
    for ((i=0; i<$numaNodesTotal; i++)); do # from node1, node2...
        coreNumaNum=$( lscpu | grep "NUMA node${i} CPU(s):" | awk '{print $NF}' | tr "," " " ) # [0-5, 12-17]
        busyCoreTotalCount=0
        for word in $coreNumaNum; do # 0-5 12-17
            for ((j=$( echo $word | cut -d"-" -f1 ); j<=$( echo $word | cut -d"-" -f2 ); j++)); do
                #printf "%d " $j
                if ${checkIfCpuUtilizationOverHighboundArray[$j]}; then
                    (( busyCoreTotalCount++ ))
                fi
            done
            #echo
        done
        busyCoreTotalArray+=( $busyCoreTotalCount )
    done
    unset coreNumaNum busyCoreTotalCount
    #echo "busyCoreTotalArray:" ${busyCoreTotalArray[@]}
}
# Find the most idle Numa Array
busyCoreTotalMin=""
mostIdleNumaArray=()
most_idle_numa() {
    busyCoreTotalMin=${busyCoreTotalArray[0]}
    for ((i=0; i<${#busyCoreTotalArray[@]}; i++)); do
        if [[ "${busyCoreTotalArray[$i]}" -lt "$busyCoreTotalMin" ]]; then
            busyCoreTotalMin=${busyCoreTotalArray[$i]}
        fi
    done
    
    for ((i=0; i<${#busyCoreTotalArray[@]}; i++)); do
        if [[ "${busyCoreTotalArray[$i]}" -eq "$busyCoreTotalMin" ]]; then
            mostIdleNumaArray+=( $i )
        fi
    done
    #echo "mostIdleNumaArray:" ${mostIdleNumaArray[@]}
}
# Group Processes To Same Numa
groupProcessesToSameNumaOfCoresArray=()
group_processes_to_same_numa_of_cores_array() {
    # These processes can allocate in same NUMA
    if [[ "${#processPidArray[@]}" -le "$(($coresTotal / $numaNodesTotal - $busyCoreTotalMin ))" ]]; then
        #echo "group_processes_to_same_numa_of_cores_array:" $(($coresTotal / $numaNodesTotal - $busyCoreTotalMin ))
        coreNumaNum=$( lscpu | grep "NUMA node${mostIdleNumaArray[0]} CPU(s):" | awk '{print $NF}' | tr "," " " ) # [0-5, 12-17]
        for word in $coreNumaNum; do # 0-5 12-17
            for ((j=$( echo $word | cut -d"-" -f1 ); j<=$( echo $word | cut -d"-" -f2 ); j++)); do
                avaliableGroupProcessesToSameNumaOfCoresArray+=( $j )
            done
        done
        #echo "avaliableGroupProcessesToSameNumaOfCoresArray" ${avaliableGroupProcessesToSameNumaOfCoresArray[@]}
        endIndex=${#processPidArray[@]}
        for ((i=0; i<${#avaliableGroupProcessesToSameNumaOfCoresArray[@]}; i++)); do
            if ! ${checkIfCpuUtilizationOverHighboundArray[${avaliableGroupProcessesToSameNumaOfCoresArray[$i]}]}; then
                groupProcessesToSameNumaOfCoresArray+=( ${avaliableGroupProcessesToSameNumaOfCoresArray[$i]} )
                (( endIndex-- ))
                #echo "endIndex" $endIndex
            fi
            if [[ "$endIndex" == "0" ]]; then break; fi
        done
    fi
    unset coreNumaNum avaliableGroupProcessesToSameNumaOfCoresArray endIndex
}

#
# clean
#
clean() {
    unset groupProcessesToSameNumaOfCoresArray
    unset busyCoreTotalMin mostIdleNumaArray
    unset busyCoreTotalArray
    unset checkIfCpuUtilizationOverHighboundArray
    unset coresTotal threadsPerCore coresPerSocket numaNodesTotal
    unset processPidArray
    unset highBound
    unset argArray
}

#
# main function
#
cpu_utilization_over_highbound_cores_total
most_idle_numa
group_processes_to_same_numa_of_cores_array
echo ${groupProcessesToSameNumaOfCoresArray[@]}
clean
