#!/usr/bin/env bash

######## mk_newicks.sh ###########

echo "\"`basename $0`\" split alignment files in FASTA format separated by "=\n" and make newick for each"
echo "Usage:"
echo "	`basename $0` mapping-file  alignment-file"

fmap="$1"
falign="$2"

if [ "$fmap" = "" ]; then echo "No mapping file! quitting ...\n" && exit 1; fi
if [ "$falign" = "" ]; then echo "No alignment file! quitting...\n" && exit 1; fi

# separate files
#splitfile -d splitted -s '=\s*\n' "$falign"

# 1. use fa2phy.py to convert from FASTA format to PHYLIP format
# 2. use RAxML (raxmlHPC) to make phylog tree in Newick format
## 3. use newicktopdf to plot tree
# 4. clear TMP files

cd splitted
if ! [ -e newicks ]; then mkdir newicks; fi
if ! [ -e work_tmp ]; then mkdir work_tmp; fi
cd work_tmp
LogFile="../../Log.txt"
rm -f "${LogFile}"
#time for i in `cd ..; ls *.fasta`; do 
# use find instead of ls since ls may lead to "Argument list too long" error
time for i in `cd ..; find . -type f -name \*\.fasta`; do 
	i=`basename "${i}"`
	echo "" >> "${LogFile}"
	echo "####################### ${i} #########################" >> "${LogFile}"
	#fa2phy.py "../${i}" "${i}.phy" >> "${LogFile}"
	fa2phy.py --remove-replicates --map-file="../../${fmap}" "../${i}" "${i}.phy" >> "${LogFile}"
	raxmlHPC -n TMP -m GTRGAMMA -s "${i}.phy" >> "${LogFile}"
	if [ -e RAxML_result.TMP ]; then mv RAxML_result.TMP "../newicks/${i%.*}".newick; fi
	# create PDF from newick
	#if [ -e RAxML_result.TMP ]; then newicktopdf RAxML_result.TMP; fi
	#if [ -e RAxML_result.pdf ]; then mv RAxML_result.pdf "../charts/${i%.*}".pdf; fi
	rm -rf *
	done
cd ..
rmdir work_tmp
cd ..


