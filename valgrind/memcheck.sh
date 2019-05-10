#!/bin/sh

echo $*
if [ $# != 1 ];then
	echo "usage: $0 program"
	exit 1
fi

valgrind --tool=memcheck --leak-check=full ./$*
