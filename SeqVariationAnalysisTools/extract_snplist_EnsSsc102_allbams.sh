#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=4000
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=extract_snps
#SBATCH --partition=ABGC_Low
module load samtools/0.1.19
BAMS=`ls /lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/BAMS/*.reA.bam`
ALLBAMS=`for BAM in $BAMS; do awk -v bam=$BAM 'BEGIN {printf " " bam}'; done`
samtools mpileup -l List_dbsnp.bed.txt -uf /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/Sus_scrofa.Sscrofa10.2.72.dna.toplevel.fa $ALLBAMS | bcftools view -Acg - >allbams_mpileup_withlist.raw.vcf
