#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./averageCpuUtilizationPerCore.sh [<interval_time> <monitor_times>] -P <core_num>"
    exit 0
fi
core_num="ALL"
core_num_index=0
interval_time=1
monitor_times=3
if [[ "${argArray[*]}" == *"-P"* ]]; then
    for ((i=0; i<${#argArray[@]}; i++)); do
        if [ "${argArray[$i]}" = "-P" ] && [ $i -gt 0 ]; then
            interval_time=${argArray[0]}
            if [[ $i -gt 1 ]]; then
                monitor_times=${argArray[1]}
            fi
        fi
        if [ "${argArray[$i]}" = "-P" ] && [ "${argArray[$(($i + 1))]}" != "" ]; then
            core_num=${argArray[$(($i + 1))]}
            core_num_index=$(($i + 1))
            break
        fi
    done
elif [[ ${#argArray[@]} -gt 0 ]]; then
    interval_time=${argArray[0]}
    if [[ ${#argArray[@]} -gt 1 ]]; then
        monitor_times=${argArray[1]}
    fi
fi
 
#echo "mpstat $interval_time $monitor_times -P $core_num"   
averageUtilizationPerCoreArray=()
list_cpu_utilization() {
    mapfile -t mpstatArray < <( mpstat $interval_time $monitor_times -P $core_num )

    core_num_total=1
    if [[ $core_num -eq "ALL" ]]; then 
        core_num_total=$( cat /proc/cpuinfo | grep processor | wc -l )
        for ((j=$((-1 * $core_num_total)); j<0; j++)); do
            #echo ${mpstatArray[$j]}
            averageUtilizationPerCoreArray+=( $(printf "%0.2f" $( echo 100.00 - $(echo ${mpstatArray[$j]} | rev | cut -d" " -f1 | rev) | bc -l )) )
        done
    else
        #echo ${mpstatArray[-1]}
        averageUtilizationPerCoreArray+=( $(printf "%0.2f" $( echo 100.00 - $(echo ${mpstatArray[-1]} | rev | cut -d" " -f1 | rev) | bc -l)) )
    fi

    unset mpstatArray core_num_total
}


#
# clean
#
clean() {
    unset averageUtilizationPerCoreArray
    unset argArray
    unset core_num core_num_index
    unset interval_time monitor_times
}

list_cpu_utilization
echo ${averageUtilizationPerCoreArray[@]}
clean

