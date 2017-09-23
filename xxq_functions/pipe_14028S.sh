#!/usr/bin/env bash

#################### map to 14028S ####################

# need genome_14028S.fasta, and plasmid_14028S.fasta
# the WDBRLT differential analysis have to be fold change

RLTDIR="$1"
SRC="$2"
DATAPREFIX="$3"
WDBRLT="$4"
CHR="$5"
GRP1="$6"
GRP2="$7"
THRESHOLD="$8"
COL="$9"

fasta_genome=`dirname "$0"`"/genome_14028S.fasta"
fasta_plasmid=`dirname "$0"`"/plasmid_14028S.fasta"

#if [ "$GRP1" = "" ]; then GRP1=`head -1 "${RLTDIR}/${WDBRLT}" | sed -n 's/.*\tA\t\([^\t]*\)\t.*/\1/1 p'`; fi
#if [ "$GRP2" = "" ]; then GRP2=`head -1 "${RLTDIR}/${WDBRLT}" | sed -n 's/.*\tA\t[^\t]*\t\([^\t]*\)\t.*/\1/1 p'`; fi
if [ "$GRP1" = "" ]; then GRP1=1; fi
if [ "$GRP2" = "" ]; then GRP2=1; fi
if [ "$THRESHOLD" = "" ]; then THRESHOLD=1; fi
if [ "$COL" = "" ]; then COL="Seq minus tail"; fi
if [ ! -e "$SRC" ] && [ -e "$RLTDIR/$SRC" ]; then SRC="$RLTDIR/$SRC"; fi
if [ ! -e "$WDBRLT" ] && [ -e "$RLTDIR/$WDBRLT" ]; then 
	WDBRLT="$RLTDIR/$WDBRLT"; 
	TILENAME="${WDBRLT%_transposon_table_*.txt}_on_${CHR}_tiles.txt"
else
	TILENAME="${RLTDIR}/${WDBRLT%_transposon_table_*.txt}_on_${CHR}_tiles.txt"
fi

#TILENAME="${RLTDIR}/${WDBRLT%_transposon_table_*.txt}_on_14028S_tiles.txt"
RLTNAME="${TILENAME%.txt}_allinfo.txt"

# map to genome
if [ ! -e "$RLTDIR/${DATAPREFIX}_on_14028S.txt" ]; then
	#./mapipe_14028S.sh -d ${RLTDIR} -n "Seq minus tail" ${DATAPREFIX}.txt
	# map on chromsome 
	map2chr.sh -d "${RLTDIR}" -n chr_14028S -g "${fasta_genome}" -o "${DATAPREFIX}_on_14028S.txt" -s "${COL}" "${SRC}"
	# map on plasmid
	map2chr.sh -d "${RLTDIR}" -n plasmid_14028S -g "${fasta_plasmid}" -o "${DATAPREFIX}_on_14028S.txt" "${SRC}"
fi

# get 5 bases downstream
#if ! [ -e "${TILENAME}" ]; then
#	#getSeqByChrStrandStartEnd -c chromosome -d strand -s probe_start -e probe_end --chr-name=chr_14028S --chr-seq=genome_14028S.fasta --chr-name=plasmid_14028S --chr-seq=plasmid_14028S.fasta --position=downstream --shift=0 --length=5 --append -o ${RLTDIR}/${DATAPREFIX}_on_14028S_down5.txt -i $RLTDIR/${DATAPREFIX}_on_14028S.txt
#	python codes/findTilingProbesAt.py -i "${RLTDIR}/${DATAPREFIX}_on_14028S.txt" -o "${TILENAME}" -t "${RLTDIR}/${WDBRLT}" --chr=chr_14028S --group1="${GRP1}" --group2="${GRP2}"
#fi
findTilingProbesAt.py -i "${RLTDIR}/${DATAPREFIX}_on_14028S.txt" -o "${TILENAME}" -t "${WDBRLT}" --chr="${CHR}" --group1="${GRP1}" --group2="${GRP2}" --threshold="${THRESHOLD}"

# exapnd rows with cells of multiple values
#expandrows ${TILENAME} | expandrows --join=', ' -c 'unique_id (+)' -c 'unique_id (-)' > ${TILENME%.txt}_expand.txt

# add intensity values
#addinfo -a 'M' -a 'A' -a 'HA_R132_chkVI_Input_MGD1029_Cy3_580.1' -a 'HA_R130_chkVI_D09chk04CecalTissue_Cy3_580.1' --by-col='unique_id (+)' --by-col2='unique_id' -i ${TILENAME%.txt}_expand.txt "${RLTDIR}/${WDBRLT}" | addinfo -a 'M' -a 'A' -a 'HA_R132_chkVI_Input_MGD1029_Cy3_580.1' -a 'HA_R130_chkVI_D09chk04CecalTissue_Cy3_580.1' --by-col='unique_id (+)' --by-col2='unique_id' "${RLTDIR}/${WDBRLT}" | sed '1s/\t\(M\)\t/\t\1 (+)\t/1;1s/\t\(A\)\t/\t\1 (+)\t/1;1s/\t\(HA_R132_chkVI_Input_MGD1029_Cy3_580.1\)\t/\t\1 (+)\t/1;1s/\t\(HA_R130_chkVI_D09chk04CecalTissue_Cy3_580.1\)\t/\t\1 (+)\t/1;1s/\t\(M\)\t/\t\1 (-)\t/1;1s/\t\(A\)\t/\t\1 (-)\t/1;1s/\t\(HA_R132_chkVI_Input_MGD1029_Cy3_580.1\)\t/\t\1 (-)\t/1;1s/\t\(HA_R130_chkVI_D09chk04CecalTissue_Cy3_580.1\)\t/\t\1 (-)\t/1' > "${TILENAME%.txt}_expand_intensity.txt"


# 1. use "bindcols" add seq name
# 2. use expand to expand every row with multiple hits on the genome
# 3. use "map" to add columns for tile strand
# 4. use "stackcols" to move columns for negative strand to columns for positive strand (but in new rows)
# 5. use "sed" to change columns for positive strand to neutral name, and other column names
# 6. use "expandrows" to expand every row of multiple "unique_id" into rows of single unique_id
# 7. use "addinfo" to add information columns for each unique_id (column 11 in the intermediate file, and column 33 in WDBRLT)
#stackcols --by-index -a 11 -a 12 -a 13 -a 14 -a 15 -a 16 -a 17 -a 18 -a 19 -a 29 -b 20 -b 21 -b 22 -b 23 -b 24 -b 25 -b 26 -b 27 -b 28 -b 30 | 

#bindcols -i "${RLTDIR}/${DATAPREFIX}.txt" 'Seq Name' -i "${TILENAME}" |
bindcols -i "${SRC}" 'Seq Name' -i "${TILENAME}" |
expandrows |
map --append -t tile_strand -t tile_strand_neg -f '("+", "-")' | 
stackcols --by-index -a 11-19 -a 29 -b 20-28 -b 30 | 
sed '1s/, +//g; 1s/ (+)//g; 1s/probe_start/oligo_H2P2_start/1; 1s/probe_end/oligo_H2P2_end/1' |
expandrows --join=', ' -c 'unique_id' |
addinfo --by-col=11 --by-col2=$(index -f "${WDBRLT}" unique_id) --by-index -a 23-`cols --no-name "${WDBRLT}"` "${WDBRLT}" > "${RLTNAME}"

#addinfo --by-col=11 --by-col2=33 --by-index -a 23-73 "${RLTDIR}/${WDBRLT}" > "${RLTNAME}"


