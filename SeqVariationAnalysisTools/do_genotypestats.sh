#!/bin/bash
#SBATCH --time=4800
#SBATCH --ntasks=1
#SBATCH --mem=16000
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=test_maker
#SBATCH --partition=ABGC_Low
#SBATCH --constraint=normalmem
python stats_from_vcf_windex_popstats_ped.py -f all.UG.raw3.vcf.gz -p "LW22 LW22F01 LW22F02 LW22F03 LW22F04 LW22F06 LW22F08 LW22F09 LW22M04,LW36 LW36F01 LW36F02 LW36F03 LW36F04 LW36F05 LW36F06 LW36F08,nd LW22F07" >genotypestats_withpops.txt
