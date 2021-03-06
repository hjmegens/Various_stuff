package SearchNCBI;
use strict;
use warnings;

use LWP::Simple;

sub gene_network_neighborhood {
	my $i=0;
	my $db     = "gene";
	my ($query, $depth)  = @_; #($query="IGF1\t3479");$query2="ESR2\t2100");

	my @results = ();
	
	push (@results, $query);
	my @final = @results;
	for ($i=0; $i < $depth; ++$i){ 

		#print "round $i:\n";
		@results = get_all_interactions($db,\@results);
		push (@final,@results);

	}
	return (\@final);
	
}

sub intersecting_networks {
	my $i=0;
	#my $depth1 = 0;
	#my $depth2 = 0;
	my $db     = "gene";
	my ($query, $query2, $depth)  = @_; #($query="IGF1\t3479");$query2="ESR2\t2100");

	my @results1 = ();
	push (@results1, $query);

	for ($i=0; $i < $depth; ++$i){ 
	#while (scalar @results1 < 50){

		#print "round $i:\n";
		#$depth1++;
		@results1 = get_all_interactions($db,\@results1);

	}
	
	my @results2 = ();

	push (@results2, $query2);

	for ($i=0; $i < $depth; ++$i){ 
	#while (scalar @results2 < 50){
		#print "round $i:\n";
		#$depth2++;
		@results2 = get_all_interactions($db,\@results2);

	}

	
	my @both = shared_array_elements(\@results1,\@results2);
	
	#return (\@both,\@results1,\@results2,$depth1,$depth2);
	return (\@both,\@results1,\@results2);
	
}

sub fetch_gene_interactions_ncbi {
	my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
	my ($db,$query)= @_;
	my @sub_return=();
	my $efetch = "$utils/efetch.fcgi?" . "retmode=text&db=$db&id=$query";    

	my $efetch_result = get($efetch);

	#$efetch_result =~ m/type generif,\n      heading "Interactions",(.+)\n    },\n/gs;
	$efetch_result =~ m/type generif,\n      heading "Interactions",(.+)\n    }/gs;

	my $interactions = $1;
	if ($interactions) {
		while ($interactions =~ /src {\s+db "GeneID",\s+tag id (\d+)\s+},\s+anchor "(\w+)"\s+},\s+{\s+src {/gs){
			my $gene_id = $1;
			my $gene = $2;
	  
			#print "$gene\t$gene_id\n------------\n";
			#print OUT "$gene\t$gene_id\n------------\n";
			push (@sub_return, "$gene\t$gene_id");
		}
	}
	my @return = unique_array_elements(@sub_return);
	return @return;

	

}
sub fetch_gene_interactions {
	my @sub_return=();
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	#my $passwd = '******';
	#my $user = 'root';

	#my $kvl = DBI->connect("dbi:mysql:$database:$server", $user, $passwd);
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);

	
	my ($db, $entrez_gene_id)=@_;
	my $query = "select assoc_entrez_gene from interactions where entrez_gene_id = ('$entrez_gene_id')";
	my $sql = $kvl->prepare($query);
	$sql->execute();
	my @results = ();
	
	while (my $row = $sql->fetchrow_arrayref) {	
			my $assoc_gene_id = join("\t", @$row);
			if ($assoc_gene_id){
				my @genes = Fetch_Ortholog::entrez_gene_id($assoc_gene_id);
				push (@sub_return, "$genes[0]\t$assoc_gene_id");
			}	
		
	}
	
	$kvl->disconnect;
	
	my @return = unique_array_elements(@sub_return);
	return @return;

	

}

sub unique_array_elements {
	my @sub_return = @_;
	my @return=();
	my %seen = ();
	foreach my $item (@sub_return) {
		unless ($seen{$item}) {
	        # if we get here, we have not seen it before
	        	$seen{$item} = 1;
	        	push(@return, $item);
		}
	}
	return @return;
}

sub unique_first_array_elements {
	my ($refA,$refB) = @_;
	my @arrayA = @$refA;
	my @arrayB = @$refB;
	my %seen = ( );                    # lookup table to test membership of B
	my @aonly = ( );                   # answer

	# build lookup table
	foreach my $item (@arrayB) { $seen{$item} = 1 }

	# find only elements in @A and not in @B
	foreach my $item (@arrayA) {
	    unless ($seen{$item}) {
	        # it's not in %seen, so add to @aonly
	        push(@aonly, $item);
	    }
	}
	return(@aonly);
}

sub shared_array_elements {
	my ($refA,$refB) = @_;
	my @arrayA = @$refA;
	my @arrayB = @$refB;
	my %seen = ();                    # lookup table to test membership of B
	my @both = ();                   # answer

	# build lookup table
	foreach my $item (@arrayB) { $seen{$item} = 1 }

	# find only elements in @A and not in @B
	foreach my $item (@arrayA) {
	    if ($seen{$item}) {
	        # it's not in %seen, so add to @aonly
	        push(@both, $item);
	    }
	}
	return(@both);
}

sub get_all_interactions {
	my ($db, $resref) = @_;
	my @results =@$resref;
	my @results2 = ();
	foreach my $element (@results){
		print $element."\n";
		my @int = split ("\t", $element);
		my $query = $int[1];
		#print $query."\n";
		my @int2 = fetch_gene_interactions($db,$query);
		#print "@int";
		push (@results2, @int2);
	
	}
	
	@results2 = unique_array_elements(@results2);
	return @results2;
}

1;

