if [ ! "$blat2_work" ]; then
    echo -e '\n$blat2_work not defined\n'
    exit 1
fi

check_status() {
    set -- `blat2_get_server $1`
    printf "%-14s on $1 at port $2" $chr
    if [ $# -ne 4 ]; then
	echo -e "\tNO HOST/PORT DATA"
	return 2
    fi
    if ! tell $1 $2 < /dev/null 2> /dev/null; then
	echo -e "\tNOT RUNNING"
	return 2
    else
	echo -e "\tok"
	return 0
    fi
}
