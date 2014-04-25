#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=64000
#SBATCH --ntasks=16
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=all_vcf
#SBATCH --partition=ABGC_Low
CHROM=$1
START=$2
END=$3
INDS=`cat inds_pigs.txt`

# for IND in $INDS; do CMD=`echo '/lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/vcf_gatk/'$IND'_rh.dedup_st.reA.UG.raw.vcf.gz'`; echo $CMD ; tabix $CMD $CHROM:$START-$END | awk '$6>40'  | awk '{print $1"_"$2"_"$4"/"$5}' ; done | sort | uniq -c >vars_$CHROM-$START-$END.txt

for IND in $INDS; do CMD=`echo '/lustre/nobackup/WUR/ABGC/shared/Pig/Mapping_results/vcf_gatk/'$IND'_rh.dedup_st.reA.UG.raw.vcf.gz'`; echo $CMD ; tabix $CMD $CHROM:$START-$END | awk '$6>40'  | awk '{print $1"_"$2}' ; done | sort | uniq -c | sed 's/^ \+//' | sed 's/ \+/\t/' | awk '$1>3' >vars_$CHROM-$START-$END.flt.txt

#cat vars_$CHROM-$START-$END.txt | sed 's/^ \+//' | sed 's/ \+/\t/' | awk '$1>3' >vars_$CHROM-$START-$END.flt.txt
#cat vars_$CHROM-$START-$END.flt.txt | sed 's/_/\t/g' | cut -f3 | sort | uniq -c | sed 's/^ \+//' | sed 's/ \+/\t/' | awk '$1>1' | cut -f2 >notuse$CHROM-$START-$END.txt

#cat vars_$CHROM-$START-$END.flt.txt | python filtervars.py -f notuse$CHROM-$START-$END.txt >vars_$CHROM-$START-$END.flt_round2.txt
#cat vars_$CHROM-$START-$END.flt_round2.txt | cut -f1,2,3 | awk '{print $2,$3-1,$3}' | sed 's/ \+/\t/g' >vars_$CHROM-$START-$END.bed

cat vars_$CHROM-$START-$END.flt.txt | cut -f2 | sed 's/_/\t/' | awk '{print $1,$2-1,$2}' | sed 's/ \+/\t/g' | sort -k2 -n >vars_$CHROM-$START-$END.bed


VARS=`cat bamlist.txt`
ALLVARS=`for VAR in $VARS; do awk -v var=$VAR 'BEGIN {printf " -I " var}'; done`

#java7 -Xmx4g -jar /cm/shared/apps/SHARED/GATK/GATK3.1/GenomeAnalysisTK.jar -R /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/Sus_scrofa.Sscrofa10.2.72.dna.toplevel.fa -T UnifiedGenotyper $ALLVARS --dbsnp /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/dbSNP/dbSNP.vcf -stand_call_conf 50.0 -stand_emit_conf 10.0 -glm BOTH -out_mode EMIT_ALL_SITES -L vars_$CHROM-$START-$END.bed -o $CHROM-$START-$END-ug_mp.vcf

#java7 -Xmx4g -jar /cm/shared/apps/SHARED/GATK/GATK3.1/GenomeAnalysisTK.jar -R /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/Sus_scrofa.Sscrofa10.2.72.dna.toplevel.fa -T UnifiedGenotyper $ALLVARS --dbsnp /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/dbSNP/dbSNP.vcf -stand_call_conf 50.0 -stand_emit_conf 10.0 -glm BOTH -out_mode EMIT_ALL_SITES -L vars_$CHROM-$START-$END.bed -o $CHROM-$START-$END-ug_mp.vcf

java7 -Xmx60g -jar /cm/shared/apps/SHARED/GATK/GATK2.6/GenomeAnalysisTK.jar -nt 15 -R /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/Sus_scrofa.Sscrofa10.2.72.dna.toplevel.fa -T UnifiedGenotyper $ALLVARS --dbsnp /lustre/nobackup/WUR/ABGC/shared/Pig/Sscrofa_build10_2/Ensembl72/dbSNP/dbSNP.vcf -stand_call_conf 50.0 -stand_emit_conf 10.0 -glm BOTH -L vars_$CHROM-$START-$END.bed -o $CHROM-$START-$END-ug_mp.vcf

bgzip $CHROM-$START-$END-ug_mp.vcf

