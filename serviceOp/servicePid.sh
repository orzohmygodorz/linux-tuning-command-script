#
# Parse the command line arguments
#
argArray=("$@")
if [[ "${#argArray[@]}" == "0" ]]; then
    echo "Usage: ./servicePid.sh -s <service_name>"
    exit 0
fi
service_name=${argArray[0]}
unset argArray

#
# Get service Pids
#
service_pid_array=()
get_service_pid() {
    mapfile -t psArray < <( ps -mo pid,tid,comm -C $service_name )
    #echo ${psArray[@]}
    for ((i=0; i<${#psArray[@]}; i++)); do
        if [[ "${psArray["$i"]}" == *"$service_name"* ]]; then
            #echo "${psArray["$i"]}"
            for j in "${psArray["$i"]}"; do
                service_pid_array+=( "$( echo "$j" | cut -d" " -f 1)" )
                break
            done
        fi
    done
    unset psArray
}

#
# clean
#
clean() {
    unset service_pid_array
    unset service_name
}

#
# main function
#
get_service_pid
echo ${service_pid_array[@]}
clean
