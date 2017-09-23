#!/usr/bin/env bash

KEY="$1"
SRC="$2"
OBJ="$3"
if [ ! "$KEY" ] || [ ! "$SRC" ]; then exit 0; fi
if [ ! "$OBJ" ]; then 
	if [ "${SRC##*.}" = "${SRC}" ]; then
		OBJ="${SRC%.*}_sort"
	else
		OBJ="${SRC%.*}_sort.${SRC##*.}"
	fi
fi

TMPFILE=$(mktemp)
awk '/^[0-9]+/{print $1}' "$KEY" > "$TMPFILE"
sortFieldsByKey.py -k "$TMPFILE" -s ":"  "$SRC"  "$OBJ" 


