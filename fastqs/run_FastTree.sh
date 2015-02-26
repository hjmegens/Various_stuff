#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=16000
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=raxml
#SBATCH --partition=ABGC_Low
#for Y in $YS; do python select_Ys.py -f fas/$Y.fa | sed 's/ Y$//' | sed 's/fas\///' >>allY.fa; done
FastTree -gtr -nt allY.fa >Y_FastTree.tre
