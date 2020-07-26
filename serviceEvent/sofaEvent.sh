# sofaEvent.sh

filename=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")") 
serviceName="${filename%%Event*}"
#echo $serviceName
optimService=("lfsm_io" "lfsm_bh")

#
# Analysis
#
printf "\n#\n# Analysis\n#\n\n"
echo "=== Check If There is a CPU-bound Service ==="
bash "$(realpath --relative-to="$PWD" $(find / -name checkIfCpubound.sh))"; echo

echo "=== Average Cpu Utilization Per Core ==="
averageUtilizationPerCoreArg="--duration-time 10 --cpu ALL"
echo $averageUtilizationPerCoreArg
averageUtilizationPerCoreArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name averageCpuUtilizationPerCore.sh))" 1 10 --P ALL )
averageUtilizationPerCoreArray=( $averageUtilizationPerCoreArray )
echo "averageUtilizationPerCoreArray:" ${averageUtilizationPerCoreArray[@]}; echo

echo "=== Check If CPU Utilization Over Highbound? ==="
checkIfCpuUtilizationOverHighboundArg="--high-bound 60.00 --duration-time 5 --cpu ALL"
echo $checkIfCpuUtilizationOverHighboundArg
checkIfCpuUtilizationOverHighboundArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name checkIfCpuUtilizationOverHighbound.sh))" --analysis-result ${averageUtilizationPerCoreArray[@]} $checkIfCpuUtilizationOverHighboundArg )
checkIfCpuUtilizationOverHighboundArray=( $checkIfCpuUtilizationOverHighboundArray )
echo "checkIfCpuUtilizationOverHighboundArray:" ${checkIfCpuUtilizationOverHighboundArray[@]}; echo

printf "\n#\n# Strategy\n#\n\n"
echo "=== Group Processes To Same Numa ==="
for ((i=0; i<${#optimService[@]}; i++)); do
    groupProcessesToSameNumaOfCoresArg="--process-name ${optimService[$i]}"
    groupProcessesToSameNumaOfCoresArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name groupProcessesToSameNuma.sh))" --analysis-result ${checkIfCpuUtilizationOverHighboundArray[@]} $groupProcessesToSameNumaOfCoresArg )
    groupProcessesToSameNumaOfCoresArray=( $groupProcessesToSameNumaOfCoresArray )
    echo "${optimService[$i]}" "groupProcessesToSameNumaOfCoresArray:" ${groupProcessesToSameNumaOfCoresArray[@]};
done


