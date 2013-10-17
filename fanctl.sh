#!/bin/bash

# Path to applesmc (path in sysfs)
FANCTL_ASMC="/sys/devices/platform/applesmc.768"

# Fan to control (file ${FANCTL_ASMC}/${FANCTL_FID}_*)
FANCTL_FID="fan1"

# Thermo to read (file ${FANCTL_ASMC}/${FANCTL_TID}_*)
FANCTL_TID="temp7"

# Time between runs (seconds)
FANCTL_INTERVAL=5

# Frequency scaling model (mapping temp -> freq)
# - input  scale C/10^3
# - output scale rpm
function scale {
    echo $(($1 / 5 - 10000))
}

# Don't edit below this line
function norm {
    [ $1 -lt $2 ] && echo $2 && return
    [ $1 -gt $3 ] && echo $3 && return
    echo $1
}

function run {
    read temp
    freq=$(norm `scale $temp` $1 $2)
    echo $freq
}

function main()
{
    [ $EUID -ne 0 ] && echo "Run it as root." && return 1

    # hack!
    sleep 1

    tempin="${FANCTL_ASMC}/${FANCTL_TID}_input"
    fanmin="${FANCTL_ASMC}/${FANCTL_FID}_min"
    fanmax="${FANCTL_ASMC}/${FANCTL_FID}_max"
    fantog="${FANCTL_ASMC}/${FANCTL_FID}_manual"
    fanout="${FANCTL_ASMC}/${FANCTL_FID}_output"

    [ ! -r $tempin ] && echo "${tempin}: Not a readable file." && return 1
    [ ! -r $fanmin ] && echo "${fanmin}: Not a readable file." && return 1
    [ ! -r $fanmax ] && echo "${fanmax}: Not a readable file." && return 1
    [ ! -w $fantog ] && echo "${fantog}: Not a writeable file." && return 1
    [ ! -w $fanout ] && echo "${fanout}: Not a writeable file." && return 1

    [ `cat $fantog` -ne 1 ] && echo "1" > $fantog

    printf "< %s\n" $tempin
    printf "> %s\n" $fanout

    temp=0
    freq=0

    while [ 1 ] ; do
        run `cat $fanmin` `cat $fanmax` < $tempin > $fanout
        printf "temp = %i C/10^3 freq = %4i rpm\n" $temp $freq
        sleep $FANCTL_INTERVAL
    done
}

main ${@} && exit ${!}
