. subs.sh

combine() {
    cat "$1" "$3" > /tmp/combine.fa.$$
    cat "$2" "$4" > /tmp/combine.qual.$$
    echo /tmp/combine.fa.$$ /tmp/combine.qual.$$
}
