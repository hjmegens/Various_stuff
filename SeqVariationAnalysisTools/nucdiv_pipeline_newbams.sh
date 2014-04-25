#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=4000
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=ngstheta
#SBATCH --partition=ABGC_Low
module load samtools/0.1.19

VAR=`gunzip -c /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/vcf_gatk/$1_rh.dedup_st.reA.UG.raw.vcf.gz | grep -v '^#' | awk '$6>30' | cut -f10 | cut -d':' -f3 | head -1000000 | sort | uniq -c | sed 's/^ \+//' | sed 's/ \+/\t/' | sort -k1 -nr | head -1 | cut -f2`
MAX=$(($VAR * 2))

MIN=$(( $VAR / 3 ))
if [ $MIN -lt 5 ]; then MIN=4; fi

echo "$1 max_depth $MAX min_depth $MIN" >$1.coverage
samtools mpileup -uf /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/Sus_scrofa.Sscrofa10.2.72.dna.toplevel.fa /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/BAMS/$1_rh.dedup_st.reA.bam | bcftools view -bvcg - > $1.mig.bcf
bcftools view $1.mig.bcf | vcfutils.pl varFilter -d$MIN -D$MAX > $1.mig.vcf
awk '$6 >= 20' $1.mig.vcf > $1.miguel.vcf
samtools mpileup -Bq 20 -d 50000 /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/BAMS/$1_rh.dedup_st.reA.bam | perl covXwin-v3.1.pl -v $1.miguel.vcf -w 50000 -d $MIN -m $MAX -b /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/BAMS/$1_rh.dedup_st.reA.bam | ./ngs_theta -d $MIN -m $MAX > $1.wintheta
