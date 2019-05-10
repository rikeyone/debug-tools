#!/bin/sh

echo $*
if [ $# != 1 ];then
	echo "usage: $0 program"
	exit 1
fi

rm callgrind.out.*
valgrind --tool=callgrind ./$*
#
#gprof2dot -f callgrind -n0 -e0 callgrind.out* > callgrind.dot
#gprof2dot -f callgrind -n10 -e10 callgrind.out* > callgrind.dot
#
gprof2dot -f callgrind -n0 -e0 --root=main callgrind.out* > callgrind.dot
dot -Tpng callgrind.dot -o callgrind.png
eog callgrind.png &
