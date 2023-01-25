#!/bin/bash

CPU_AFFINITY=$1

IFS=', ' read -r -a CPUSET <<< "${CPU_AFFINITY}"
if [[ ${#CPUSET[@]} == 0 ]]; then
        echo "you must provide cpu affinity"
fi

for i in ${CPUSET[@]}; do
        taskset -c ${i} /bin/bash -c "while : ; do : ; done &"
done
