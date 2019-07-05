#!/bin/sh

#install perf
sudo apt-get install linux-tools-common
sudo apt-get install linux-tools-`uname -r`

#install Brendan Gregg's FlameGraph scripts and perf-tools scripts
git clone --depth 1 https://github.com/brendangregg/FlameGraph.git
git clone --depth 1 https://github.com/brendangregg/perf-tools.git 



