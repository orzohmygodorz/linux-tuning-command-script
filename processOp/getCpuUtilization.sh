#
# Parse the command line arguments
#
argArray=("$@")
if [[ "${#argArray[@]}" == "0" ]]; then
    echo "Usage: ./getCpuUtilization.sh <process_name>"
    echo "Usage: ./getCpuUtilization.sh <process_name> <cpu_monitor_duration>"
    exit 0
fi
process_name=${argArray[0]}

pidArray=$( ./getPid.sh "$process_name" )
pidArray=( $pidArray )

#
# 
# pidstat format: 12:42:36 PM   UID       PID    %usr %system  %guest    %CPU   CPU  Command
cpu_monitor_duration=3
if [[ ${argArray[1]} != "" ]]; then cpu_monitor_duration=${argArray[1]}; fi
declare -A cpuUtilizationMatrix
list_process_cpu_utilization() {
    for ((i=0; i<${#pidArray[@]}; i++)); do
        cpuUtilizationMatrix[$i,0]=${pidArray[$i]}
        mapfile -t pidstatArray < <( pidstat 1 $cpu_monitor_duration -p ${pidArray[$i]} )
        for ((j=0; j<(($cpu_monitor_duration + 3)); j++)); do
            if [[ $j -lt "3" ]]; then continue; fi

            #echo ${pidstatArray[$j]}
            #printf "%d %f\n" ${pidArray[$i]} $( echo ${pidstatArray[$j]} | cut -d' ' -f8)
            #printf "%f " $( echo ${pidstatArray[$j]} | cut -d' ' -f8 )
            cpuUtilizationMatrix[$i,(( $j - 2 ))]=$( echo ${pidstatArray[$j]} | cut -d' ' -f8 )
            echo $( echo ${pidstatArray[$j]} | cut -d' ' -f10 )
        done
        #cpuUtilizationMatrix[$i,(( 1 + $cpu_monitor_duration + 1 ))]=$( echo ${pidstatArray[$j]} | cut -d' ' -f10 )
        unset pidstatArray
    done
}

#
# clean
#
clean() {
    unset cpuUtilizationMatrix
    unset cpu_monitor_duration
    unset pidArray
    unset process_name
    unset argArray
}

list_process_cpu_utilization
for ((i=0; i<${#pidArray[@]}; i++)); do
    printf "%d " ${cpuUtilizationMatrix[$i,0]}
    for ((j=0; j<$cpu_monitor_duration; j++)); do
        printf "%f " ${cpuUtilizationMatrix[$i,(( $j + 1 ))]}
    done
    echo
done
clean
