#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./executePidCoreMapping.sh --pid-core-mapping <pid_core_mapping>"
    exit 0
fi
pidCoreMapping=()
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--pid-core-mapping" ]]; then
        iIndex=1
        while [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "--" ] && [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "" ]; do
            pidCoreMapping+=( ${argArray[$((i + iIndex))]} )
            ((iIndex++))
        done
        unset iIndex
        #echo "pidCoreMapping:" ${pidCoreMapping[@]}
    fi
done

execute_pid_core_mapping() {
    for ((i=0; i<${#pidCoreMapping[@]}; i+=2)); do
        #echo "pid, core" ${pidCoreMapping[$i]} ${pidCoreMapping[$((i + 1))]}
        taskset -cp ${pidCoreMapping[$((i + 1))]} ${pidCoreMapping[$i]}
    done
}

#
# main function
#
execute_pid_core_mapping
