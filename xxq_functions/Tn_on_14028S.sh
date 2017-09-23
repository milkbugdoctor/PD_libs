#!/usr/bin/env bash

#################### map to 14028S ####################

echo "\"`basename $0`\" maps sequences onto 14028S genome and find potential insert of transposons."
echo "Usage: "
echo "    `basename $0`  Sequence_file  Seq_Colname  [ Request_file [ Channel_No_in_group1  Channel_No_in_group2  [ Thresold ] ] ]"
echo

RLTDIR="rlt"
SRC="$1"
DATAPREFIX="${1%.txt}"
COL="$2"
REQS="$3"
GRP1="$4"
GRP2="$5"
THRESHOLD="$6"

if [ "$SRC" = "" ] || [ ! -e "$SRC" ]; then exit 1; fi
if [ "$REQS" = "" ]; then REQS="reqs.txt"; fi
if [ ! -e "$REQS" ]; then exit 1; fi
if [ "$GRP1" = "" ]; then GRP1=1; fi
if [ "$GRP2" = "" ]; then GRP2=1; fi
if [ "$THRESHOLD" = "" ]; then THRESHOLD=1; fi

for req in `cat "${REQS}"`; do
	if [ -e "${req}_transposon_table_14028S_all_probes.txt" ]; then
		pipe_14028S.sh  "${RLTDIR}"  "${SRC}"  "${DATAPREFIX}"  "${req}_transposon_table_14028S_all_probes.txt" chr_14028S "${GRP1}" "${GRP2}" "${THRESHOLD}" "${COL}"; 
	fi
	if [ -e "${req}_transposon_table_14028S_plasmid_all_probes.txt" ]; then
		pipe_14028S.sh  "${RLTDIR}"  "${SRC}"  "${DATAPREFIX}"  "${req}_transposon_table_14028S_plasmid_all_probes.txt" plasmid_14028S "${GRP1}" "${GRP2}" "${THRESHOLD}" "${COL}"; 
	fi
done

cd "${RLTDIR}"

for chr in chr_14028S plasmid_14028S; do
	if [ -e `head -1 ../"${REQS}" | sed 's/\(.*\)/\1_on_'"${chr}"'_tiles_allinfo.txt/g'` ]; then
		mergefiles --right-reps=order --by-col="seq_id" --by-col="chromosome" --by-col="strand" --by-col="oligo_H2P2_start" --by-col="oligo_H2P2_end" --by-col="unique_id" --by-col="tile_strand" --by-col="Seq Name" --by-col="probe_seq" --by-col="n_mismatch" --by-col="perc_match" --by-col="genome_seq"   `cat ../"${REQS}" | sed 's/\(.*\)/\1_on_'"${chr}"'_tiles_allinfo.txt/g'` | 
		rmcols --rm-all "X.1" |
		addColTail.py `cat ../"${REQS}"` |
		mergerepcols --skip-blank --remove-reps -o "Tn_on_${chr}_col_uni.txt"
	fi
done

cd ..


