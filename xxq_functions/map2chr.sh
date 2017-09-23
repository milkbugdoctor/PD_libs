#!/usr/bin/env sh

showHelp() {
	echo map2chr.sh
	echo 	map sequences onto a chromosome
	echo Usage:
	echo 	map2chr.sh [-h] [-c] [-d obj_dir] [-f file_prefix] [-b BLAST_DIR] -n genome_name -g genome_seq.fasta [-D genome_DB] [-o output_file] -s seq_col seq_table
	echo -h: Optional switch. For help and quit
	echo -c: Optional switch. For clean and quit
	echo -d: Optional result directory. The default is "."
	echo -f: Optional file prefix. The default is the base name of seq_table without the last extension
	echo -b: Optional. The directory of BLAST. The default is "NCBI"
	echo -n: The genome name
	echo "-g: The genome sequence file (in FASTA format)"
	echo -D: Optional. The BLAST database formatted from the genome sequence file. The default is same to the genome sequence file
	echo -o: Optional. The output file.
	echo -s: The name for the sequence column in the "seq_table" file
	echo seq_table: the TAB-like file containing the sequences.
	exit 0
	}

#set -x

blast_dir=`dirname "$0"`"/NCBI"

# optional options
clean_all="false"
obj_dir="."
#chr_db=fn_prefix=""

# mandatory options
#chr_name=chr_seq=seq_tab=seq_col=""

# set up option format
#args=`getopt cd:f:n: $*`
#set -- "args"
args=`getopt -o hcd:f:n:g:D:o:s: -- "$@"`
eval set -- "$args"

# get options
for i in `seq $#`
do
	if [ $i -le $# ]; then
		case "${!i}" in
			-h) showHelp;;
			-c) clean_all="true";;
			-d) shift; obj_dir="${!i}";;
			-f) shift; fn_prefix="${!i}";;
			-b) shift; blast_dir="${!i}";;
			-n) shift; chr_name="${!i}";;
			-g) shift; chr_seq="${!i}";;
			-D) shift; chr_db="${!i}";;
			-o) shift; seq_map="${!i}";;
			-s) shift; seq_col="${!i}";;
			*) seq_tab="${!i}";;
		esac
	fi
done

# set default values.
if [ "$chr_db" = "" ]; then chr_db="`basename ${chr_seq}`"; fi
if [ "$fn_prefix" = "" ]; then
	seq_tab_base="`basename \"${seq_tab}\"`"
	fn_prefix="${seq_tab_base%.*}"
fi
if ! [ "$obj_dir" = "." -o "$obj_dir" = "" ]; then fn_prefix="${obj_dir}/${fn_prefix}"; fi
if [ "$seq_map" = "" ]; then
	seq_map="${fn_prefix}_on_${chr_name}.txt"
else
	seq_map="${obj_dir}/${seq_map}"
fi

# set intermediate files
seq_fna="${fn_prefix}.fna"
seq_blast="${fn_prefix}_BLAST_${chr_name}.txt"

# clean and exit
if [ "$clean_all" = "true" ]; then
	rm -rf "${seq_fna}" "${seq_blast}" "${seq_map}"
	exit 0
fi

# check mandatory options
if [ "$chr_name" = "" ]; then echo "Error: no chromosome name provided!"; fi
if [ "$chr_seq" = "" ]; then echo "Error: no chromosome sequence file provided!"; fi
if [ "$seq_tab" = "" ]; then echo "Error: no sequence file provided!"; fi
if [ "$seq_col" = "" ] && [ ! -e "$seq_fna" ]; then echo "Error: no name for sequence column provided!"; fi
if [ "$chr_name" = "" -o "$chr_seq" = "" -o "$seq_tab" = "" ] || [ "$seq_col" = "" -a ! -e "$seq_fna" ]; then showHelp; fi


# check/create result directory
if ! [ -e "$obj_dir" ]; then
	echo "making $obj_dir"
	mkdir -p "$obj_dir"
fi

# check/create seq file in FASTA format
if ! [ -e "${seq_fna}" ]
then
	mkSeqFna -s "$seq_col" -o "${seq_fna}" "${seq_tab}"
fi

# check/create BLAST database
if ! [ -e "${blast_dir}/data/${chr_db}.nsq" ]; then
	"${blast_dir}"/bin/formatdb -i "$chr_seq" -p F -o F -n "${blast_dir}/data/${chr_db}"
fi

# check/BLAST
if ! [ -e "${seq_blast}" ]; then
	"${blast_dir}"/bin/blastall -p blastn -i "${seq_fna}" -m 9 -FF -S 3 -e 2 -d "${blast_dir}"/data/"$chr_db" > "${seq_blast}"
fi

# map sequences onto chromosome
maprobe -s "${seq_fna}" -o "$seq_map" -g "$chr_name" --genome-file="$chr_seq" -b "$seq_blast" -e 5 -p 0.95 --no-MMs --keep-all


