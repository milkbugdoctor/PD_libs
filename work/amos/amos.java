#!/bin/bash

java_opts=

#
# I found this to be the best garbage collector.
# Your mileage may vary.
#
java_opts="$java_opts -XX:+UseSerialGC -XX:NewRatio=8"

#
# You may need to increase your stack or heap space.
# If so, uncomment and edit this line:
#
# java_opts="$java_opts -Xmx5400m -Xss50m"

exec java $java_opts "$@"

# Other Java options that have been used before:
#     -Xloggc:gc.log
#     -XX:ParallelGCThreads=2 -XX:NewRatio=8
#     -XX:+UseConcMarkSweepGC -XX:+UseCMSCompactAtFullCollection
#     -Xrs
#     -Xprof

