#!/bin/bash
#SBATCH --time=10000
#SBATCH --mem=60000
#SBATCH --ntasks=16
#SBATCH --nodes=1
#SBATCH --constraint=normalmem
#SBATCH --output=output_%j.txt
#SBATCH --error=error_output_%j.txt
#SBATCH --job-name=raxml
#SBATCH --partition=ABGC_Low
#for Y in $YS; do python select_Ys.py -f fas/$Y.fa | sed 's/ Y$//' | sed 's/fas\///' >>allY.fa; done
raxmlHPC-PTHREADS-SSE3 -T 15 -s allY.fa -o BABA03U01 -m GTRGAMMA -n youtrax -p 1 | grep -v 'undetermined values'
#raxmlHPC-PTHREADS-SSE3 -T 15 -N 10 -s x53-x62_selection.phy -o OM001_Warthog_SSCX -m GTRGAMMA -n x53-62raxml_selection -p 1 | grep -v 'undetermined values'
