#
# CPU Parameters
#
coresTotal=$( cat /proc/cpuinfo | grep processor | wc -l )
threadsPerCore=$( lscpu | grep 'Thread(s) per core:' | awk '{print $NF}' )
coresPerSocket=$( lscpu | grep 'Core(s) per socket:' | awk '{print $NF}' )
numaNodesTotal=$( lscpu | grep 'NUMA node(s):' | awk '{print $NF}' )

