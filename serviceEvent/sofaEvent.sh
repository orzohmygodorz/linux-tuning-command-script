#
# clean last test
#
cp /usr/sofa/config/sofa_config.xml_old /usr/sofa/config/sofa_config.xml
rm -f $(find / -name sofaResult)

# sofaEvent.sh
filename=$(basename "$(test -L "$0" && readlink "$0" || echo "$0")") 
serviceName="${filename%%Event*}"
#echo $serviceName
optimService=("lfsm_io" "lfsm_bh")
indexService=0

#
# SOFA Event
#
printf "\n#\n# Initial SOFA Service\n#\n\n"
fio /root/00_rw.fio > sofaResult &
sofaPid=$!
while kill -0 $sofaPid 2> /dev/null; do
    sleep 1
done
grep -F "IOPS" $(find / -name sofaResult)

printf "\n#\n# Second SOFA Service\n#\n\n"
fio /root/00_rw.fio > sofaResult &
sofaPid=$!
sleep 2

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
groupProcessesToSameNumaOfCoresArg="--process-name ${optimService[$indexService]}"
groupProcessesToSameNumaOfCoresArray=$( bash "$(realpath --relative-to="$PWD" $(find / -name groupProcessesToSameNuma.sh))" --analysis-result ${checkIfCpuUtilizationOverHighboundArray[@]} $groupProcessesToSameNumaOfCoresArg )
groupProcessesToSameNumaOfCoresArray=( $groupProcessesToSameNumaOfCoresArray )
echo "${optimService[$indexService]}" "groupProcessesToSameNumaOfCoresArray:" ${groupProcessesToSameNumaOfCoresArray[@]};

printf "\n#\n# Executer\n#\n\n"
echo "=== SOFA Modify Optimization Config ==="
bash "$(realpath --relative-to="$PWD" $(find / -name sofaModifyOptimizationConfig.sh))" --service-name ${optimService[$indexService]} --core-list ${groupProcessesToSameNumaOfCoresArray[@]} 
echo

#
# Performance after optimization
#
echo "=== Performance After Optimization ==="
while kill -0 $sofaPid 2> /dev/null; do
    sleep 1
done
grep -F "IOPS" $(find / -name sofaResult)



