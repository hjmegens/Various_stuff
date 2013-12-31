package R_BioC;

use strict;
use warnings;
sub gene_set_enrichment {

my ($species,$tempdir,$pval,$fh,$fhht,$rbioc_generef) = @_;
my @rbioc_genes = @$rbioc_generef;
my $infile = $tempdir.'/temp/rbioc_genes.txt';
my $outfile = $tempdir.'/temp/rbioc_filtergenes.txt';
my $gostats = $tempdir.'/temp/rbioc_gostats.txt';
open (GENES, ">$infile") or warn $!;
foreach my $gene (@rbioc_genes){
	print GENES "$gene\n";
}
close(GENES);

my $ensembl_dataset;
if ($species eq 'human'){
	$ensembl_dataset = 'hsapiens_gene_ensembl';
}
if ($species eq 'chicken'){
	$ensembl_dataset = 'ggallus_gene_ensembl';
}
if ($species eq 'house_mouse'){
	$ensembl_dataset = 'mmusculus_gene_ensembl';
}
if ($species eq 'dog'){
	$ensembl_dataset = 'cfamiliaris_gene_ensembl';
}
if ($species eq 'cattle'){
	$ensembl_dataset = 'btaurus_gene_ensembl';
}
if ($species eq 'horse'){
	$ensembl_dataset = 'ecaballus_gene_ensembl';
}
if ($species eq 'zebrafish'){
	$ensembl_dataset = 'drerio_gene_ensembl';
}
unless ($ensembl_dataset){
#	die " is not a valid species!!\n";
}
open(RIN, ">$tempdir/temp/Rin.txt");
print RIN 'library(biomaRt)'."\n";
print RIN 'genes <- read.table("'.$infile.'", header=FALSE)'."\n";
print RIN 'genes <- t(genes)'."\n";
print RIN 'ensembl = useMart("ensembl",dataset="'.$ensembl_dataset.'")'."\n";
print RIN 'ensembl_hs = useMart("ensembl",dataset="hsapiens_gene_ensembl")'."\n";
unless ($species eq 'human'){
	print RIN 'hs.bt = getBM(attributes=c("ensembl_gene_id","human_ensembl_gene") ,mart=ensembl)'."\n";
	print RIN 'hs.bt2 <- unique(hs.bt[!is.na(hs.bt$human_ensembl_gene),2])'."\n";
#print RIN 'head(hs.bt2)'."\n";
	print RIN 'hs.genes = getBM(attributes=c("ensembl_gene_id","human_ensembl_gene"),filters="ensembl_gene_id",values=genes, mart=ensembl)'."\n";
	print RIN 'hs.genes2 <- unique(hs.genes[!is.na(hs.genes$human_ensembl_gene),2])'."\n";
}

	
if ($species eq 'human'){
	print RIN 'hs.bt = getBM(attributes=c("ensembl_gene_id") ,mart=ensembl)'."\n";
	print RIN 'hs.bt2 <- unique(hs.bt[!is.na(hs.bt$ensembl_gene_id),])'."\n";
	print RIN 'hs.genes = getBM(attributes=c("ensembl_gene_id"),filters="ensembl_gene_id",values=genes, mart=ensembl)'."\n";
	print RIN 'hs.genes2 <- unique(hs.genes[!is.na(hs.genes$ensembl_gene_id),])'."\n";
}
print RIN 'hs.genes3 = getBM(attributes=c("ensembl_gene_id","hgnc_symbol"),filters="ensembl_gene_id",values=hs.genes2, mart=ensembl_hs)'."\n";
print RIN 'hs.genes_entrez = getBM(attributes=c("ensembl_gene_id","entrezgene"),filters="ensembl_gene_id",values=hs.genes2, mart=ensembl_hs)'."\n";
print RIN 'hs.genes_entrez2 <- unique(hs.genes_entrez[!is.na(hs.genes_entrez$entrezgene),2])'."\n";
print RIN 'hs.bt_entrez = getBM(attributes=c("ensembl_gene_id","entrezgene"),filters="ensembl_gene_id",values=hs.bt2, mart=ensembl_hs)'."\n";
print RIN 'hs.bt_entrez2 <- unique(hs.bt_entrez[!is.na(hs.bt_entrez$entrezgene),2])'."\n";
print RIN "library(GOstats)\nlibrary(hgu95av2.db)"."\n";
print RIN 'params_temp <- new("GOHyperGParams", geneIds=hs.genes_entrez2, universeGeneIds=hs.bt_entrez2, annotation = "hgu95av2.db", ontology = "BP",pvalueCutoff='.$pval.', conditional = FALSE, testDirection = "over")'."\n";
print RIN 'results = hyperGTest(params_temp)'."\n";
print RIN 'summary(results)'."\n";
print RIN 'hs.genes_info <- getBM(attributes=c("ensembl_gene_id","entrezgene","hgnc_symbol","go_biological_process_id"),filters = "entrezgene",values = hs.genes_entrez2, mart=ensembl_hs)'."\n"; 
print RIN 'length(unique(hs.genes_info$entrezgene))'."\n";
print RIN 'all <- hs.genes_info[hs.genes_info$go%in%summary(results)$GOBPID,]'."\n";
print RIN 'length(unique(all$entrezgene))'."\n";
unless ($species eq 'human'){
	print RIN 'filter <- hs.bt[hs.bt$human_ensembl_gene%in%all$ensembl_gene_id,]'."\n";
	print RIN 'length(filter)'."\n";
	print RIN 'filter <- filter[filter$ensembl_gene_id%in%genes,]'."\n";
	print RIN 'length(filter)'."\n";
	print RIN 'write.table(filter$ensembl_gene_id, "'.$outfile.'",col.names=FALSE, row.names=FALSE, quote=FALSE)'."\n";
}
if ($species eq 'human'){
	print RIN 'filter <- hs.bt[hs.bt$ensembl_gene_id%in%all$ensembl_gene_id,]'."\n";
	print RIN 'filter <- as.matrix(filter)'."\n";
	print RIN 'length(filter)'."\n";
	print RIN 'filter <- filter[filter[,1]%in%genes,]'."\n";

	print RIN 'length(filter)'."\n";
	print RIN 'write.table(filter, "'.$outfile.'",col.names=FALSE, row.names=FALSE, quote=FALSE)'."\n";
}

print RIN 'dim(summary(results))'."\n";
#[1] 18  7
print RIN 'write.table(summary(results), "'.$gostats.'",sep = "\t",col.names=FALSE, row.names=TRUE, quote=FALSE)'."\n";
print RIN 'q()'."\n";
close (RIN);

`R --no-save <$tempdir/temp/Rin.txt >$tempdir/temp/Rout_bioc.txt`;

open (GENES, "$outfile") or warn $!;
my @genes =();
while (<GENES>){
	my $gene = $_;
	chomp $gene;
	push(@genes,$gene);
}
close(GENES);
open (GOSTATS, "$gostats") or warn $!;
my @gostatarray =();
while (<GOSTATS>){
	my $stat = $_;
	chomp $stat;
	push(@gostatarray,$stat)
}
close(GOSTATS);
print "\n---------\nExpression profile (UniGene):\n";
print $fh "\n---------\nExpression profile (UniGene):\n";
print $fhht "<hr><h3>Significan GO terms:</h3><br>\n";
print $fhht '<table border="1"><tr><th>GO-ID</th><th>PVal</th><th>OddsR.</th><th>ExpC.</th><th>Count</th><th>Size</th><th>Term</th></tr>';
foreach my $stat (@gostatarray){
	my @statarray = split("\t",$stat);
	print "$stat\n";
	print $fh "$stat\n";
	print $fhht "<tr><td>$statarray[1]</td><td>$statarray[2]</td><td>$statarray[3]</td><td>$statarray[4]</td><td>$statarray[5]</td><td>$statarray[6]</td><td>$statarray[7]</td></tr>\n";
}
print $fhht '</table>';
return(\@genes,\@gostatarray);
}
1;
