#!/bin/bash

if [ "`uname -m`" = "x86_64" ]; then
    opts="-J-d64"
fi

if [ $# -ne 1 ]; then
    echo -e "\nUsage: $0 pid\n"
    exit 1
fi

tmp=dump.$$
echo dump file is $tmp 1>&2
jmap $opts -dump:file=$tmp,format=b $1
echo Running jhat $tmp ... 1>&2
jhat -J-mx8000m $tmp &
echo When web server is ready run: firefox http://localhost:7000
