#
# Parse the command line arguments
#
argArray=("$@")
if [[ "${#argArray[@]}" == "0" ]]; then
    echo "Usage: ./getPid.sh <process_name>"
    exit 0
fi
process_name=${argArray[0]}
unset argArray

#
# Get service Pids
#
service_pid_array=()
get_service_pid() {
    mapfile -t psArray < <( ps -A | grep "$process_name*" )
    #echo ${psArray[@]}
    for ((i=0; i<${#psArray[@]}; i++)); do
        #echo ${psArray[$i]}
        if [[ "${psArray["$i"]}" == *"$process_name"* ]]; then
            #echo "${psArray["$i"]}"
            for j in "${psArray["$i"]}"; do
                j=( $j )
                # Print lfsm_bh0 ~ lfsm_bh2
                #echo $( echo "$j" | cut -d":" -f 3 | cut -d" " -f 2)
                service_pid_array+=( "$( echo "$j" | cut -d" " -f 2)" )
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
    unset process_name
}

#
# main function
#
get_service_pid
echo ${service_pid_array[@]}
clean
