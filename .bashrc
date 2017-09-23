# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions


PATH=$PATH:~/exe/
PATH=$PATH:/sc/kzd/home/desaip18/soft
PATH=$PATH:~/UCI_scripts/mature/
PATH=$PATH:~/soft/orthomclSoftware-v2.0.9/bin/


PATH=$PATH:/sc/kzd/home/desaip18/soft/bowtie2-2.2.5
#PATH=$PATH:/sc/kzd/home/desaip18/soft/a5_miseq_linux_20140604/bin
PATH=$PATH:/sc/kzd/home/desaip18/soft/a5_miseq_linux_20160825/bin
PATH=$PATH:/sc/kzd/home/desaip18/exe/bin
PATH=$PATH:/sc/kzd/home/desaip18/soft/STAR/bin/Linux_x86_64
PATH=$PATH:/sc/kzd/home/desaip18/soft/FastQC
#PATH=$PATH:/sc/kzd/home/desaip18/soft/a5_miseq_linux_20140604/bin

PATH=$PATH:/sc/kzd/home/desaip18/soft/tophat-2.1.0.Linux_x86_64
PATH=$PATH:/sc/kzd/home/desaip18/soft/subread-1.4.6-p2-Linux-x86_64/bin
PATH=$PATH:/sc/kzd/home/desaip18/soft/mauve_snapshot_2015-02-13/
PATH=$PATH:/sc/kzd/home/desaip18/soft/mauve_snapshot_2015-02-13/linux-x64/
PATH=$PATH:/sc/kzd/home/desaip18/soft/AlignGraph/AlignGraph
PATH=$PATH:/sc/kzd/home/desaip18/soft/ucsc_tools
PATH=$PATH:/sc/kzd/home/desaip18/soft/genometools-1.5.8/bin
PATH=$PATH:/sc/kzd/home/desaip18/soft/snp_sites/src/
PATH=$PATH:/sc/kzd/home/desaip18/soft/MUMmer3.23/
PATH=$PATH:/sc/kzd/home/desaip18/soft/proteinortho_v5.11/
PATH=$PATH:/sc/kzd/home/desaip18/.local/bin
PATH=$PATH:/sc/kzd/home/desaip18/.local/
PATH=$PATH:/sc/kzd/home/desaip18/soft/Sibelia-3.0.6-Linux/bin/
PATH=$PATH:/sc/kzd/home/desaip18/exe/kraken/
PATH=$PATH:/bin
PATH=$PATH:/usr/local/bin
PATH=$PATH:~/exe/bin/surpi
PATH=$PATH:/sc/kzd/home/desaip18/soft/Quake/bin/
PATH=$PATH:/sc/kzd/home/desaip18/soft/SUPERFOCUS_0.26/
PATH=$PATH:/sc/kzd/home/desaip18/soft/wgs-8.3rc2/Linux-amd64/bin/
PATH=$PATH:/sc/kzd/home/desaip18/soft/sas_alpha/bin
PATH=$PATH:/sc/kzd/home/desaip18/soft/phylosift_20140419/
PATH=$PATH:/sc/kzd/home/desaip18/soft/gb_taxonomy_tools/gb_taxonomy_tools-1.0.0/
PATH=$PATH:/sc/kzd/home/desaip18/soft/tabix-0.2.6/
#PATH=$PATH:/sc/kzd/home/desaip18/soft/kaiju/bin
#PATH=$PATH:/sc/kzd/home/desaip18/soft/nsegata-phylophlan-8e2d2ec74872/
PATH=$PATH:/sc/kzd/home/desaip18/soft/jvarkit/dist/
PATH=$PATH:/sc/kzd/home/desaip18/UCI_scripts/work/amos
PATH=$PATH:/sc/kzd/home/desaip18/UCI_scripts/work/
#PATH=$PATH://sc/kzd/app/x86_64/python/2.7.10/bin/$PATH
PATH=$PATH:/sc/kzd/home/desaip18/soft/RSEM-1.3.0/
PATH=$PATH:~/soft/bbmap/

module load sge
#module load perl
#module load bioperl
#module load barrnap
#module load infernal
#module load aragorn
#module load prodigal
#module load blast
#module load hmmer
#module load minced
#module load ncbitools
#module load prokka
#module load java
#module load cytoscape
#module load RSeQC
#module load kaiju
#module load java
#module load beagle-lib
#module load raxml/8.2.7
#module load SRA

#module load python/2.7.10 
#module unload python



#module load MetaPhlAn
#module load phylophlan
#module load muscle
#module load cd-hit
#module load shortbred
#module load mafft


module load R/3.2.3-shlib
module load rstudio


#module unload python
#module load python/2.7.10
#module load glibc/2.14

export bioinfo='/sc/kzd/proj/bioinfo/'
export mydb='/sc/kzd/proj/bioinfo/pd_databases'
export nextseq='/sc/kzd/shared/rw/bioinfo/Nextseq500_processeddata/'




#PATH=$PATH:/sc/kzd/app/x86_64/sge/2011.11/bin/linux-x64/

export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/UCI_scripts/fred_perl_libraries/
export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/exe/bioperl/share/perl5/
export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/soft/sas/modules_alpha/lib
export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/soft/sas_alpha/lib
export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/soft/vcftools-vcftools-2543f81/src/perl
export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/soft/
#export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/exe/bioperl/lib/site_perl/5.20.2/x86_64-linux-thread-multi

export {http,https,ftp}_proxy='http://kzd-nd-wsa-3.corp.zoetis.com:3128'
export {HTTP,HTTPS,FTP}_PROXY='http://kzd-nd-wsa-3.corp.zoetis.com:3128'
export {TMP,TEMP,tmp,temp}='/scratch'
#export PYTHONPATH=/sc/kzd/home/desaip18/.local/lib/python2.7/site-packages:PYTHONPATH
export PYTHONPATH=/sc/kzd/home/desaip18/soft/nsegata-phylophlan-8e2d2ec74872/taxcuration:PYTHONPATH

#export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64/jre
export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.6.13.0/
export VARSCAN_JAR=/sc/kzd/home/desaip18/soft/VarScan.v2.3.7.jar
export LMAT_DIR=/sc/kzd/home/desaip18/lmatdb/runtime_inputs/runtime_inputs/

#export EC2_HOME=/usr/local/ec2/ec2-api-tools-1.6.13.0/


export ALLOW_WGCNA_THREADS=24

### EXPORTED BY MOCAT ###
export PERL5LIB=$PERL5LIB:/sc/kzd/home/desaip18/soft/MOCAT/src
PATH=$PATH:/sc/kzd/home/desaip18/soft/MOCAT/src
### EXPORTED BY MOCAT ###




#source /sc/kzd/app/x86_64/p3/20161201/deployment/user-env.sh
#export P3=/sc/kzd/app/x86_64/p3
#export DEP=$P3/20161201/deployment

export SENTIEON_LICENSE=/sc/kzd/home/ponnar02/apps/Secondary-Analysis/GoldenHelix-Zoetis_cluster.lic
PATH=$PATH://sc/kzd/home/ponnar02/apps/Secondary-Analysis/tools/sentieon/bin/

