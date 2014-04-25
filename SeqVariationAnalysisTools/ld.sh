echo $1
cat important_plinkfiles/hm8_5.ped | grep ^$1 >$1.ped
cp important_plinkfiles/hm8_5.map $1.map
plink --file $1 --out $1 --missing-genotype N --noweb --r2 --ld-window-kb 1000 --ld-window 99999 --ld-window-r2 0 --maf 0.05 --hwe 0.001 --geno 0.05
R CMD BATCH "--args $1" ld.R

