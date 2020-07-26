#
# Parse the command line arguments
# ps -mo pid,%cpu -p 7132 | sed -n 2p | awk {'{print $2}'}
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./getCpuUtilizationOfProcesses.sh <process_name>"
    echo "Usage: ./getCpuUtilizationOfProcesses.sh <process_name> <cpu_monitor_duration>"
    exit 0
fi
process_name=${argArray[0]}

pidArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getPid.sh))" "$process_name" )
pidArray=( $pidArray )
cpu_monitor_duration=3
if [[ ${argArray[1]} != "" ]]; then cpu_monitor_duration=${argArray[1]}; fi
pidstatCommand="pidstat 1 1 "
declare -A cpuUtilizationMatrix
for ((i=0; i<${#pidArray[@]}; i++)); do
    pidstatCommand+="-p ${pidArray[$i]} "
    cpuUtilizationMatrix[$i,0]=${pidArray[$i]}
done

#
# CPU Utilization
# pidstat format: 12:42:36 PM   UID       PID    %usr %system  %guest    %CPU   CPU  Command
pidstatArray=()
list_process_cpu_utilization() {
    for ((i=0; i<$cpu_monitor_duration; i++)); do
        #cpuUtilizationMatrix[$i,0]=${pidArray[$i]}
        mapfile -t pidstatArray < <( ${pidstatCommand[@]} )
        for ((j=0; j<((${#pidArray[@]} + 3)); j++)); do
            if [[ $j -lt "3" ]]; then continue; fi

            #echo ${pidstatArray[$j]}
            cpuUtilizationMatrix[$(( $j - 3 )),$(( $i + 1 ))]=$( echo ${pidstatArray[$j]} | cut -d' ' -f8 )
            #echo "${cpuUtilizationMatrix[$(( $i + 1 )),$(( $j - 3 ))]}"
        done
        #cpuUtilizationMatrix[$i,(( 1 + $cpu_monitor_duration + 1 ))]=$( echo ${pidstatArray[$j]} | cut -d' ' -f10 )
    done
}
add_command_name() {
    for ((i=0; i<${#pidArray[@]}; i++)); do
        if [[ $j -lt "3" ]]; then continue; fi

        cpuUtilizationMatrix[$i,$(( $cpu_monitor_duration + 1 ))]=$( echo ${pidstatArray[$(( $i + 3 ))]} | cut -d' ' -f 10 )
        #echo $( echo ${pidstatArray[$(( $i + 3 ))]} | cut -d' ' -f 10 )
        #echo ${cpuUtilizationMatrix[$i,$(( $cpu_monitor_duration + 1 ))]}
    done
}

#
# Print Matrix
#
print_matrix() {
    for ((i=0; i<${#pidArray[@]}; i++)); do
        printf "%d " ${cpuUtilizationMatrix[$i,0]}
        for ((j=0; j<$cpu_monitor_duration; j++)); do
            #printf "$i,$(( $j + 1 )) "
            printf "%.2f " ${cpuUtilizationMatrix[$i,$(( $j + 1 ))]}
        done
        echo ${cpuUtilizationMatrix[$i,$(( $cpu_monitor_duration + 1 ))]}
    done
}

#
# clean
#
clean() {
    unset pidstatArray
    unset cpuUtilizationMatrix
    unset pidstatCommand
    unset cpu_monitor_duration
    unset pidArray
    unset process_name
    unset argArray
}

list_process_cpu_utilization
add_command_name
print_matrix
#echo ${cpuUtilizationMatrix[@]}
clean
