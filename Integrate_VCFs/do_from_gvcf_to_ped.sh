#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=4000
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=gvcf
#SBATCH --partition=ABGC_Low
python from_gvcf_to_ped.py -s snplist60K_select1_10_11_12_13 -i inds2.txt -o test_direct_out -r snplist60K.refalleles -m direct

