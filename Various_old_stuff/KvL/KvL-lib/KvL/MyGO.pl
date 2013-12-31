#package MyGO;
use strict;
use warnings;

use DBI;
#my $search = 'GO:0051919';
	my $search = 'blood coagulation';
	if ($search =~ /GO:(\d){7}/g) {
		get_genes_from_go_acc($search);
	}
	elsif ($search =~ /GO:\d+/g) {
		print "$search is NOT a valid GO term!!\nThe program will end now, please try again!\n";
		exit;
	}
	elsif ($search =~ /^\d+/g) {
		print "$search is NOT a valid GO term!!\nThe program will end now, please try again!\n";
		exit;
	}
	else {
		get_genes_from_go_term($search);
	}


exit;
sub get_genes_from_go_term {
	my $database = 'mygo';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $mygo = DBI->connect("dbi:mysql:$database:$server", $user);
	my @return = ();
	my @goacc = ();

	my ($name)=@_;

	my $query = "select acc from term where name = '$name'";
	my $sql = $mygo->prepare($query);
	$sql->execute();
	my $acc;
	while (my $row = $sql->fetchrow_arrayref) {
		$acc = join("\t", @$row);
	}

	if ($acc){
		print "oorspronkelijk: $acc\n";
		@goacc = get_child_terms($acc,$mygo);
		push (@goacc, $acc);
		@goacc = unique_array_elements(@goacc);
		foreach my $element (@goacc){
			print "$element\n";
			$query = "select acc,name from term where acc = '$element'";
			$sql = $mygo->prepare($query);
			$sql->execute();
			while (my $row = $sql->fetchrow_arrayref) {
				my $acc_name = join("\t", @$row);
				print $acc_name."\n";
			}
		}
		
	}
		
	else {
		print "GO name $name does not exist!\nDid you perhaps mean:\n";
		$query = "select acc,name from term where name like '%$name%'";
		$sql = $mygo->prepare($query);
		$sql->execute();
		my $suggestion;
		while (my $row = $sql->fetchrow_arrayref) {
			
			$suggestion = join("\t", @$row);
			print $suggestion."\n";
			
		}
		if ($suggestion) {
			print "\nThe program will now end - please try again based on named suggestions\n+++END+++\n";
		}
		else {
			print "\nSorry: no suggestions fournd.\nThe program will now end - please try again with fewer search terms\n+++END+++\n";
		}
		exit;

	}
	$mygo->disconnect;
	my @assocgenes = get_associations(@goacc);
	print "\nassociated genes:\n";
	foreach my $gene (@assocgenes){
		print "$gene\n";
	}
	#return @return;
	
}

sub get_genes_from_go_acc {
	my $database = 'mygo';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $mygo = DBI->connect("dbi:mysql:$database:$server", $user);
	my @return = ();
	my @goacc = ();

	my ($input_acc)=@_;

	my $query = "select acc from term where acc = '$input_acc'";
	my $sql = $mygo->prepare($query);
	$sql->execute();
	my $acc;
	while (my $row = $sql->fetchrow_arrayref) {
		$acc = join("\t", @$row);
	}

	if ($acc){
		print "oorspronkelijk: $acc\n";
		@goacc = get_child_terms($acc,$mygo);
		push (@goacc, $acc);
		@goacc = unique_array_elements(@goacc);
		foreach my $element (@goacc){
			print "$element\n";
			$query = "select acc,name from term where acc = '$element'";
			$sql = $mygo->prepare($query);
			$sql->execute();
			while (my $row = $sql->fetchrow_arrayref) {
				my $acc_name = join("\t", @$row);
				print $acc_name."\n";
			}
		}
		
	}
		
	else {
		print "GO accession $input_acc does not exist!\n";
		
		print "\nplease check your GO accession and try again. \nAlternatively try entering a go name.\n+++END+++\n";
		exit;

	}
	my @assocgenes = get_associations(@goacc);
	print "\nassociated genes:\n";
	foreach my $gene (@assocgenes){
		print "$gene\n";
	}
	#return @return;
	$mygo->disconnect;
}

sub get_child_terms {
	
	my @goacc=();
	my ($acc,$mygo)=@_;
		
	my $query = "select rchild.name,rchild.acc from term as rchild, term as ancestor, graph_path where graph_path.term2_id = rchild.id and graph_path.term1_id = ancestor.id and ancestor.acc = '$acc'";

	my $sql = $mygo->prepare($query);
	$sql->execute();
		
	while (my $row = $sql->fetchrow_arrayref) {
		my $goterms = join("\t", @$row);
		my @int = split("\t",$goterms);
		push (@goacc , $int[1]); 	
		#push (@return , $goterms); 
	}
	
	return @goacc;
}	

#1;


sub get_associations {
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my @goaccs = @_;
	my @genes;
	foreach my $acc (@goaccs){
		my $query = "select approved_symbol from go_ncbi inner join hgnc_simple using (entrez_gene_id) where go_term_id = '$acc'"; 
		my $sql = $kvl->prepare($query);
		$sql->execute();
		
		while (my $row = $sql->fetchrow_arrayref) {
			my $gene = join("\t", @$row);
			push (@genes , $gene); 	
			
		}
	
	}
	@genes = unique_array_elements(@genes);
	return @genes;
	$kvl->disconnect;
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
