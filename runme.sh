#!/bin/bash

echo "cleaning up older logs"
find . -type f \( -size -100c -o -mmin +10 \) -delete -name "output-*.txt"
find . -type f \( -size -100c -o -mmin +10 \) -delete -name "dmesg-*.txt" 
find . -type f \( -size -100c -o -mmin +10 \) -delete -name "trace-*.txt" 

now=$(date '+%m%d%y-%H%M%S')

echo "setting device to root access"
adb root

echo "getting dmesg/trace logs"
adb pull /data/dmesg.txt
adb pull /data/trace.txt

echo "cleaning up the trace for sleepgraph.py"
echo "# suspend-$(date '+%m%d%y-%H%M%S') picard mem 5.4.296" > trace-${now}.txt
cat trace.txt >> trace-${now}.txt
rm trace.txt

mv dmesg.txt dmesg-${now}.txt

if [ -e trace-${now}.txt ] && [ -e dmesg-${now}.txt ]; then
    adb shell "rm /data/trace.txt"
    adb shell "rm /data/dmesg.txt"


    echo "running sleepgraph.py..."
    python3 sleepgraph.py -ftrace ./trace-${now}.txt -dmesg ./dmesg-${now}.txt
    
    mv output.html output-${now}.html
    
    echo "launching output.html in chrome"
    chrome output-${now}.html
else
    echo "problems with inputs"
fi
