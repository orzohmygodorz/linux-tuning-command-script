#
# 
#
monitor_time=120
declare -a vmstatArray_old=()
declare -a vmstatArray_new=()
declare -a vmstatArray_delta
declare -a vmstatArray_delta_level
declare -a vmstatArray_alarm
for ((i=0; i<17; i++)); do vmstatArray_alarm+=("0"); done

#
# Loop monitor process with vmstat command
#
monitor_start() {
    # the first result of vmstat is not accurate
    mapfile -t vmstatArray < <( vmstat 1 2 )
    if [[ ${#vmstatArray_old[@]} == "0" ]]; then
        vmstatArray_old=( $( echo ${vmstatArray[-2]}) )
    else
        vmstatArray_old=("${vmstatArray_new[@]}")
    fi

    vmstatArray_new=( $( echo ${vmstatArray[-1]}) )
    echo ${vmstatArray_old[@]}
    echo ${vmstatArray_new[@]}

    vmstatArray_delta=()
    for i in "${!vmstatArray_old[@]}"
    do 
        vmstatArray_delta+=($(( ${vmstatArray_new[$i]} - ${vmstatArray_old[$i]} )))
    done
    echo ${vmstatArray_delta[@]}

    vmstatArray_delta_level=()
    for i in "${!vmstatArray_old[@]}"
    do
        base=${vmstatArray_old[$i]}
        if [ "${vmstatArray_old[$i]}" == "0" ]; then
            base=1
        fi
        vmstatArray_delta_level+=($((${vmstatArray_delta[$i]} / $base)))
    done
    echo ${vmstatArray_delta_level[@]}
}

#
# Alarm
#
# system_in (interupt)
#in_alarm() {
#    
#}
# system_cs (content switch)
# Reference: https://books.google.com.tw/books?id=IagfgRiKWd4C&pg=PA442&lpg=PA442&dq=System+diagnosis+cpu+mem+io+bound&source=bl&ots=w_i3o2SuAi&sig=ACfU3U3ZV2YMe5Kpw_V5yTk-uyOZWPNKag&hl=zh-TW&sa=X&ved=2ahUKEwjun43M4a3qAhUawosBHe8uBKIQ6AEwAHoECAsQAQ#v=onepage&q=System%20diagnosis%20cpu%20mem%20io%20bound&f=false
cs_alarm() {
    if [[ ${vmstatArray_new[11]} -gt 100000 ]]; then
        vmstatArray_alarm[11]=1
    fi
}

#
# alarm_trigger
#
vmstatArray_alarm_trigger() {
    local alarm=false
    for i in ${!vmstatArray_alarm[@]}; do
        if [[ ${vmstatArray_alarm[$i]} != "0" ]]; then
            alarm=true
            break
        fi
    done
    echo "$alarm"
}

#
# clean
#
clean() {
    unset vmstatArray_old vmstatArray_new vmstatArray_delta vmstatArray_delta_level vmstatArray_alarm
}

#
# Check bottleneck of resource
#
monitor_seconds=0
while [ $monitor_seconds -lt $monitor_time ]; do
    echo "=== " $monitor_seconds " ==="
    monitor_start

    if [[ $monitor_seconds != "0" ]]; then 
        cs_alarm
    fi 
    let monitor_seconds+=1
    sleep 1

    if $(vmstatArray_alarm_trigger); then
        break
    fi
done

clean
echo ${vmstatArray_alarm[@]}
