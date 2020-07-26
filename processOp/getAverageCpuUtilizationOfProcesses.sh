#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./getAverageCpuUtilizationOfProcesses.sh --analysis-result <analysis_result> --process-name <process_name> --duration-time <duration_time>"
    exit 0
fi
analysisResult=()
process_name=""
durationTime=3
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--analysis-result" ]]; then
        index=1
        while [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "--" ] && [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "" ]; do
            analysisResult+=( ${argArray[$((i + iIndex))]} )
            ((iIndex++))
        done
        unset iIndex
        #echo ${#analysisResult[@]} ${analysisResult[@]}
    fi
    if [[ ${argArray[$i]} == "--process-name" ]]; then processName=${argArray[($i + 1)]}; fi
    if [[ ${argArray[$i]} == "--duration-time" ]]; then durationTime=${argArray[($i + 1)]}; fi 
done
processPidArray=()
if [[ "$processName" == "" ]]; then
    echo "Usage: ./getAverageCpuUtilizationOfProcesses.sh --analysis-result <analysis_result> --process-name <process_name> --duration-time <duration_time>"
    exit 0
else
    processPidArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getPid.sh))" "$processName" )
    processPidArray=( $processPidArray )
    if [[ ${#processPidArray[@]} -eq 0 ]]; then
        echo "Error Process Name."
    echo "Usage: ./getAverageCpuUtilizationOfProcesses.sh --analysis-result <analysis_result> --process-name <process_name> --duration-time <duration_time>"
        exit 0
    fi
fi

declare -a matrixCpuUtilizationOfProcessesArray
if [[ "${#analysisResult[@]}" -eq "0" ]]; then
    matrixCpuUtilizationOfProcessesArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name getMatrixCpuUtilizationOfProcesses.sh))" "$processName" "$durationTime" )
else
    matrixCpuUtilizationOfProcessesArray=( ${analysisResult[@]} )
fi
matrixCpuUtilizationOfProcessesArray=( $matrixCpuUtilizationOfProcessesArray )

#
# Matrix Operation
#
declare -A matrixCpuUtilizationOfProcessesMatrix
turn_array_to_matrix() {
    x=0
    for ((i=0; i<${#processPidArray[@]}; i++)); do
        for ((j=0; j<$(( ${#matrixCpuUtilizationOfProcessesArray[@]} / ${#processPidArray[@]} )); j++)); do
            matrixCpuUtilizationOfProcessesMatrix[$i,$j]=${matrixCpuUtilizationOfProcessesArray[$x]}
            #echo "$i,$j" ${matrixCpuUtilizationOfProcessesMatrix[$i,$j]}
            (( x++ ))
        done
    done
    unset x
}
averageMatrixCpuUtilizationOfProcessesArray=()
average_matrix_cpu_utilization_of_processes() {
    for ((i=0; i<${#processPidArray[@]}; i++)); do
        averageValue=0.00
        for ((j=1; j<=$durationTime; j++)); do
            averageValue=$(echo $averageValue + ${matrixCpuUtilizationOfProcessesMatrix[$i,$j]} | bc -l)
        done
        #echo "averageValue" $averageValue 
        averageMatrixCpuUtilizationOfProcessesArray+=( $( echo "scale=2; $averageValue / ${durationTime}.00" | bc ) )
        unset averageValue
    done
}
print_matrix() {
    for ((i=0; i<${#processPidArray[@]}; i++)); do
        printf "%d " ${matrixCpuUtilizationOfProcessesMatrix[$i,0]}
        for ((j=1; j<=$durationTime; j++)); do
            printf "%.2f " ${matrixCpuUtilizationOfProcessesMatrix[$i,$j]}
        done
        printf "%s" ${matrixCpuUtilizationOfProcessesMatrix[$i,$(( $durationTime + 1 ))]}
        echo 
    done
}

#
# clean
#
clean() {
    unset averageMatrixCpuUtilizationOfProcessesArray
    unset matrixCpuUtilizationOfProcessesMatrix
    unset matrixCpuUtilizationOfProcessesArray
    unset durationTime
    unset processPidArray
    unset processName
    unset argArray
}

#
# main function
#
turn_array_to_matrix
#print_matrix
average_matrix_cpu_utilization_of_processes
echo ${averageMatrixCpuUtilizationOfProcessesArray[@]}
clean
