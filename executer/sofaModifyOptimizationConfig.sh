#
# Parse the command line arguments
#
argArray=("$@")
if [ "${#argArray[@]}" == "0" ] || [ "${argArray[0]}" == "--help" ]; then
    echo "Usage: ./sofaModifyOptimizationConfig.sh --service-name <service_name> --core-list <core_list>"
    exit 0
fi
serviceName=""
groupProcessesToSameNumaOfCoresArray=()
for ((i=0; i<${#argArray[@]}; i++)); do
    if [[ ${argArray[$i]} == "--service-name" ]]; then serviceName=${argArray[($i + 1)]}; fi
    if [[ ${argArray[$i]} == "--core-list" ]]; then
        iIndex=1
        while [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "--" ] && [ "$(echo "${argArray[$((i + iIndex))]}" | head -c2)" != "" ]; do
            groupProcessesToSameNumaOfCoresArray+=( ${argArray[$((i + iIndex))]} )
            ((iIndex++))
        done
        unset iIndex
        #echo "pidCoreMapping:" ${pidCoreMapping[@]}
    fi
done
groupProcessesToSameNumaOfCoresString=$( IFS=$","; echo "${groupProcessesToSameNumaOfCoresArray[*]}" )
echo "groupProcessesToSameNumaOfCoresitring:" $groupProcessesToSameNumaOfCoresString

#
# SOFA Modify Optimization Config
#
sofa_modify_optimization_config() {
    sed -i "/$serviceName.*/{n;s/.*/\        <value\>${#groupProcessesToSameNumaOfCoresArray[@]}\<\/value\>/}" $(find / -name sofa_config.xml)
    sed -i "/$serviceName.*/{n;n;s/.*/\        <setting\>$groupProcessesToSameNumaOfCoresString\<\/setting\>/}" $(find / -name sofa_config.xml)
}

#
# clean
#
clean() {
    unset groupProcessesToSameNumaOfCoresString
    unset serviceName groupProcessesToSameNumaOfCoresArray
    unset argArray
}

#
# main function
#
sofa_modify_optimization_config
clean

