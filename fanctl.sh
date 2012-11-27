#!/bin/bash

# path to applesmc (in sysfs)
asmc="/sys/devices/platform/applesmc.768"

# fan to control
fid="fan1"

# thermo to read
tid="temp7"

# time between runs
interval=5

# frequency scaling model
function freq_model {
    echo $(($1 * 200 - 10000))
}

# don't edit below this line
function normalize {
    [[ $1 -lt $2 ]] && echo $2 && return
    [[ $1 -gt $3 ]] && echo $3 && return
    echo $1
}

# control paths
_fan=${asmc}/${fid}
_temp=${asmc}/${tid}

read _fan_min < ${_fan}_min
read _fan_max < ${_fan}_max

function run {
    read temp
    temp=$((${temp} / 1000))
    freq=$(freq_model ${temp})
    freq=$(normalize ${freq} ${_fan_min} ${_fan_max})
    smsg=$(printf "%s | `date` | %2i C (%s) | %4i rpm (%s)\n" ${0} ${temp} ${tid} ${freq} ${fid})
    echo ${freq}
}

# you must enable manual fan setting
echo "1" 2>/dev/null > ${_fan}_manual
if [[ ${?} -ne 0 ]] ; then
    echo "Run it as root." && exit 1
fi

while [ 1 ] ; do
    run < ${_temp}_input > ${_fan}_output
    echo ${smsg} && sleep ${interval} & wait ${!}
done


