#!/bin/sh
python systrace.py -t 8 gfx input view webview sm hal idle freq sched wm am res dalvik -o gfx_trace.html
