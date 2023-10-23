#!/bin/bash
git config --global --add safe.directory /jtcores
cd /jtcores
export JTROOT=$(pwd)
export JTFRAME=$JTROOT/modules/jtframe

source $JTFRAME/bin/setprj.sh
export PATH=$PATH:/usr/local/go/bin

BETAKEY="$2"
if [ -z "$BETAKEY" ]; then
    BETAKEY=`printf "0x%04X%04X" $RANDOM $RANDOM`
    echo "WARNING: remote compilation with no beta key. Assigning random one"
fi
BETAKEY="-d JTFRAME_UNLOCKKEY=$BETAKEY"

if [ -e $CORES/$1/cfg/macros.def ]; then
    jtframe
    # Remote builds have red OSD and beta key enabled
    jtseed 3 $1 -mister --nodbg $BETAKEY -d JTFRAME_OSDCOLOR=0x30
fi
