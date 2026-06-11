#!/bin/bash

function list_files_for_deletion
{
    find . -type f -name "output-*.txt" \( -size -100c \)
    find . -type f -name "dmesg-*.txt"  \( -size -100c \)
    find . -type f -name "trace-*.txt"  \( -size -100c \)

    find . -type f -name "output-*.txt" \( -mmin +1 \)
    find . -type f -name "dmesg-*.txt"  \( -mmin +1 \)
    find . -type f -name "trace-*.txt"  \( -mmin +1 \)
}

function list_unique_files_for_deletion
{
    list_files_for_deletion | sort -u
}

function is_files_for_deletion
{
    count=`list_unique_files_for_deletion | wc -l`
    if [ ${count} -gt 0 ]; then
	return 1
    fi

    return 0
}

is_files_for_deletion
if [ $? == 1 ]; then
    echo ===============================================
    echo "delete these files?"
    echo ===============================================
    list_unique_files_for_deletion
    echo ===============================================
    read delete_them
    if [ ${delete_them} ] && [ ${delete_them} == 'Y' ] || [ ${delete_them} == 'y' ]; then
	for file in `list_unique_files_for_deletion`
	do
	    echo deleting ${file}
	    rm ${file}
	    if [ $? != 0 ]; then
		echo "failed to delete ${file}. perms?"
		ls -alt ${file}
	    fi
	done
	echo done
    else
	echo skipped
    fi
    echo ===============================================
fi

now=$(date '+%m%d%y-%H%M%S')

echo "setting device to root access"
adb root &>/dev/null

echo "getting dmesg/trace logs"
adb pull /data/dmesg.txt &>/dev/null
adb pull /data/trace.txt &>/dev/null

if [ ! -e demsg.txt ] || [ ! -e trace.txt ]; then
    echo "failed to get traces from target"
    exit 1
fi

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
