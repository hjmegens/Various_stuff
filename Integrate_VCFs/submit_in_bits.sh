i=0
while [ $i -lt 271 ];
   do 
    JOBS=`squeue | grep all_vcf | wc -l`;
    echo 'numjobs: '$JOBS;
    if [ $JOBS -lt 10 ]; 
       then
         #read CHROM START END;
         echo 'chrom: '$CHROM' start: '$START' end: '$END;
         #sbatch do_vcf_intervals_allbams.sh $CHROM $START $END
         i=$(($i+1));
         echo 'less than 100';
         echo $i;
       else
         echo 'more than 100';
    fi;
    sleep 2;
done; 
 

