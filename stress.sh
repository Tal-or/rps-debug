#!/bin/bash

CPU_AFFINITY=$1
TIMEOUT=${2:-100000}

IFS=', ' read -r -a CPUSET <<< "${CPU_AFFINITY}"
if [[ ${#CPUSET[@]} == 0 ]]; then
        echo "you must provide cpu affinity"
fi

for i in ${CPUSET[@]}; do
        taskset -c ${i} timeout -v ${TIMEOUT}s /bin/bash -c "while : ; do : ; done" &
done
