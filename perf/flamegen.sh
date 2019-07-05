#!/bin/sh

if [ x$1 != x ];then
cat $1 | ./stackcollapse-perf.pl --all | ./flamegraph.pl --color=java --hash > perf.svg
else

sudo perf record -F 99 -a -g -- sleep 10
sudo perf script > out.perf

./stackcollapse-perf.pl out.perf > out.folded
./flamegraph.pl out.folded > perf.svg
fi

eog perf.svg &

