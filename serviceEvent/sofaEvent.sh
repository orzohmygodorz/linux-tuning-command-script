# sofaEvent.sh

#
# Analysis
#
printf "\n#\n# Analysis\n#\n\n"
echo "=== Check If There is a CPU-bound Service ==="
bash "$(realpath --relative-to="$PWD" $(find / -name checkIfCpubound.sh))"; echo

echo "=== Average Cpu Utilization Per Core ==="
echo "--duration-time 5 --cpu ALL"
averageUtilizationPerCoreArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name averageCpuUtilizationPerCore.sh))" 1 8 --P ALL )
averageUtilizationPerCoreArray=( $averageUtilizationPerCoreArray )
echo "averageUtilizationPerCoreArray:" ${averageUtilizationPerCoreArray[@]}; echo

echo "=== Check If CPU Utilization Over Highbound? ==="
echo "--high-bound 85.00 --duration-time 5 --cpu ALL"
checkIfCpuUtilizationOverHighboundArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name checkIfCpuUtilizationOverHighbound.sh))" --analysis-result ${averageUtilizationPerCoreArray[@]} --high-bound 85.00 --cpu ALL )
checkIfCpuUtilizationOverHighboundArray=( $checkIfCpuUtilizationOverHighboundArray )
echo "checkIfCpuUtilizationOverHighboundArray:" ${checkIfCpuUtilizationOverHighboundArray[@]}; echo

printf "\n#\n# Strategy\n#\n\n"
echo "=== Group Processes To Same Numa ==="
groupProcessesToSameNumaOfCoresArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name groupProcessesToSameNuma.sh))"  --analysis-result ${checkIfCpuUtilizationOverHighboundArray[@]} --process-name lfsm_bh )
groupProcessesToSameNumaOfCoresArray=( $groupProcessesToSameNumaOfCoresArray )
echo "groupProcessesToSameNumaOfCoresArray:" ${groupProcessesToSameNumaOfCoresArray[@]}; echo



