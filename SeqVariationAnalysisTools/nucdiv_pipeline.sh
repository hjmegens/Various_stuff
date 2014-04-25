#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=4000
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=ngstheta
#SBATCH --partition=ABGC_Research
module load samtools/0.1.19
VAR=`gunzip -c /lustre/nobackup/WUR/ABGC/shared/Pig/vars_hjm_newbuild10_2/vars-flt_$1-final.txt.gz  | cut -f8 | head -1000000 | sort | uniq -c | sed 's/^ \+//' | sed 's/ \+/\t/' | sort -k1 -nr | head -1 | cut -f2`
let MAX=2*VAR
echo "$1 max_depth is $MAX"
MIN=$(( $VAR / 3 ))
if [ $MIN -lt 5 ]; then MIN=4; fi

echo "$1 min_depth is $MIN"
samtools mpileup -uf /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/FASTA/Ssc10_2_chromosomes.fa /lustre/nobackup/WUR/ABGC/shared/Pig/BAM_files_hjm_newbuild10_2/$1_rh.bam | bcftools view -bvcg - > $1.mig.bcf
bcftools view $1.mig.bcf | vcfutils.pl varFilter -d$MIN -D$MAX > $1.mig.vcf
awk '$6 >= 20' $1.mig.vcf > $1.miguel.vcf
samtools mpileup -Bq 20 -d 50000 /lustre/nobackup/WUR/ABGC/shared/Pig/BAM_files_hjm_newbuild10_2/$1_rh.bam | perl covXwin-v3.1.pl -v $1.miguel.vcf -w 50000 -d $MIN -m $MAX -b /lustre/nobackup/WUR/ABGC/shared/Pig/BAM_files_hjm_newbuild10_2/$1_rh.bam | ./ngs_theta -d $MIN -m $MAX > $1.wintheta
