#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=4000
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=extractfq
#SBATCH --partition=ABGC_Low
module load samtools/0.1.19

VAR=`gunzip -c /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/vcf_gatk/$1_rh.dedup_st.reA.UG.raw.vcf.gz | grep -v '^#' | awk '$6>30' | cut -f10 | cut -d':' -f3 | head -1000000 | sort | uniq -c | sed 's/^ \+//' | sed 's/ \+/\t/' | sort -k1 -nr | head -1 | cut -f2`
MAX=$(($VAR * 2))

MIN=$(( $VAR / 3 ))
if [ $MIN -lt 5 ]; then MIN=2; fi

echo "$1 max_depth $MAX min_depth $MIN" >$1.coverage

samtools mpileup -C50 -l xlist.txt -uf /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/Sus_scrofa.Sscrofa10.2.72.dna.toplevel.fa /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/BAMS/$1_rh.dedup_st.reA.bam | bcftools view -c - | vcfutils.pl vcf2fq -d 2 -D $MAX | gzip >$1_X.fq.gz

