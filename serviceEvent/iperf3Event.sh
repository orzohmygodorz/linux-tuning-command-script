#
# iperf3Event.sh
#
filename=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")")
serviceName="${filename%%Event*}"

#
# Make events for testing
#
serviceTime=30
serverPidList=()
clientPidList=()
serverClientPairTotal=3
port=5001
fixedCpu=6
for ((i=0; i<$serverClientPairTotal; i++)); do
    iperf3 -s -p $((port + i)) >>/dev/null 2>&1 & 
    serverPidList+=( $! )
    sleep 0.2
    iperf3 -c 127.0.0.1 -p $((port + i)) -t $serviceTime > client$((port + i)) 2>&1 &
    clientPidList+=( $! )
    sleep 0.2
done
echo ${serverPidList[@]}
echo ${clientPidList[@]}
for ((i=0; i<${#serverPidList[@]}; i++)); do 
    taskset -cp $i ${serverPidList[$i]}
    taskset -cp $fixedCpu ${clientPidList[$i]}
done

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
echo "=== Decentralize Processes To Different Hyperthreading Pid Core Mapping ==="
decentralizeProcessesToDifferentHyperthreadingPidCoreMapping=$( bash "$(realpath --relative-to="$PWD" $(find / -name decentralizeProcessesToDifferentHyperthreadingPidCoreMapping.sh))" --process-name $serviceName )
decentralizeProcessesToDifferentHyperthreadingPidCoreMapping=( $decentralizeProcessesToDifferentHyperthreadingPidCoreMapping )
echo "decentralizeProcessesToDifferentHyperthreadingPidCoreMapping:" ${decentralizeProcessesToDifferentHyperthreadingPidCoreMapping[@]}

printf "\n#\n# Executer\n#\n\n"
echo "=== Execute Pid Core Mapping ==="
bash "$(realpath --relative-to="$PWD" $(find / -name executePidCoreMapping.sh))" --pid-core-mapping ${decentralizeProcessesToDifferentHyperthreadingPidCoreMapping[@]}

#
# Clean the Environment
#
clean() {
    unset checkIfCpuUtilizationOverHighboundArg checkIfCpuUtilizationOverHighboundArray
    unset averageUtilizationPerCoreArg averageUtilizationPerCoreArray
    unset serverPidList clientPidList
}

sleep $((serviceTime + 10))
for server in ${serverPidList[@]}; do
    kill $server
done
clean

