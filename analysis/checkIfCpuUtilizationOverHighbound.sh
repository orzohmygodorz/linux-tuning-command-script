#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./checkIfCpuUtilizationOverHighbound.sh --analysis-result <analysis_result> \
          --high-bound <0.00~100.00> --duration-time <seconds> --cpu <core_num>"
    exit 0
fi
analysisResult=()
highBound=90.00
durationTime=5
cpuNum="ALL"
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--analysis-result" ]]; then
        iIndex=1
        while [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "--" ] && [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "" ]; do
            analysisResult+=( ${argArray[$((i + iIndex))]} )
            ((iIndex++))
        done
        unset iIndex
    fi
    if [[ ${argArray[$i]} == "--high-bound" ]]; then highBound=${argArray[($i + 1)]}; fi
    if [[ ${argArray[$i]} == "--duration-time" ]]; then durationTime=${argArray[(i + 1)]}; fi
    if [[ ${argArray[$i]} == "--cpu" ]]; then cpuNum=${argArray[(i + 1)]}; fi
done
#echo "--high-bound" $highBound "--duration-time" $durationTime "--cpu" $cpuNum

#
# Check if CPU Utilization Over Highbound
#
averageUtilizationPerCoreArray=()
checkIfCpuUtilizationOverHighboundArray=()
check_if_cpu_utilization_over_highbound() {
    if [[ "${#analysisResult[@]}" -eq "0" ]]; then
        mapfile -t averageUtilizationPerCoreArray < <( bash "$(realpath --relative-to="$PWD" $(find / -name averageCpuUtilizationPerCore.sh))" 1 $durationTime -P $cpuNum )
    else
        averageUtilizationPerCoreArray=( ${analysisResult[@]} )
    fi
    averageUtilizationPerCoreArray=( ${averageUtilizationPerCoreArray[@]} )
    for ((i=0; i<${#averageUtilizationPerCoreArray[@]}; i++)); do
        #echo ${averageUtilizationPerCoreArray[$i]}
        if [[ "${averageUtilizationPerCoreArray[$i]}" > "$highBound" ]] || [[ "${averageUtilizationPerCoreArray[$i]}" == "100.00" ]]; then
            #echo ${averageUtilizationPerCoreArray[$i]} ">" $highBound
            checkIfCpuUtilizationOverHighboundArray+=( "true" )
        else
            #echo ${averageUtilizationPerCoreArray[$i]} "<" $highBound
            checkIfCpuUtilizationOverHighboundArray+=( "false" )
        fi
    done

    unset averageUtilizationPerCoreArray
}

#
# clean
#
clean() {
    unset averageUtilizationPerCoreArray checkIfCpuUtilizationOverHighboundArray
    unset highBound durationTime cpuNum
    unset argArray
}

#
# main function
#
check_if_cpu_utilization_over_highbound
echo ${checkIfCpuUtilizationOverHighboundArray[@]}
clean
