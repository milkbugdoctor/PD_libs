#!/usr/bin/env bash

######## mk_fasta.sh ###########

echo "\"`basename $0`\" make files in FASTA format using sequence with one base in each row."
echo "Usage:"
echo "	`basename $0` mapping-file  data-file"
echo "IMPORTANT: the sequence should be in the first column"

fmap="$1"
fsrc="$2"

if [ "$fmap" = "" ]; then echo "No mapping file! quitting ...\n" && exit 1; fi
if [ "$fsrc" = "" ]; then echo "No alignment file! quitting...\n" && exit 1; fi

# use awk to get seq, transposechars to convert columns to rows, and sed add column name
awk '{if (NR>1) print $1}'  "$fmap"  |  transposechars | sed '1s/\(.*\)/Seq\n\1/' > "${fsrc}.TMP"
bindcols -i "$fmap" Object -i "${fsrc}.TMP" > "${fsrc}_1.TMP"
mkSeqFna -i Object -s 'Seq' "${fsrc}_1.TMP" > "${fsrc%.txt}.fna"
sed '/>/!s/-/?/g' "${fsrc%.txt}.fna" > "${fsrc%.txt}_ques.fna"
rm "${fsrc}.TMP" "${fsrc}_1.TMP"
