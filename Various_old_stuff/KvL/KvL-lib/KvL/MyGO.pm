package MyGO;
use strict;
use warnings;

use DBI;

#####################################
# sub MyGO
# Masterscript for this module.
#####################################

sub MyGO {
	#################################
	# initialize local mygo db
	#################################
	my $database = 'mygo';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $mygo = DBI->connect("dbi:mysql:$database:$server", $user);
	
	# in goes a search term, either a go accession or go name

	my ($search, $fh, $fhht) = @_;

	# the next conditionals will check whether it is a valid GO accession, or a name

	if ($search =~ /GO:(\d){7}/ig) {
		$search = uc $search;
		my $original;
		my ($ok,$parents, $go_terms, $assocgenes) = get_genes_from_go_acc($search, $mygo, $fh, $fhht);		
		return ($ok, $parents, $go_terms, $assocgenes);
	}
	elsif ($search =~ /GO:\d+/ig) {
		$search = uc $search;
		print "$search is NOT a valid GO term!!\n\n";
		my $ok = 'no';
		return $ok;
	}
	elsif ($search =~ /^\d+/ig) {
		$search = uc $search;
		print "$search is NOT a valid GO term!!\n\n";
		my $ok = 'no';
		return $ok;

	}
	else {
		my $original;		
		my ($ok,$parents, $go_terms, $assocgenes) = get_genes_from_go_term($search, $mygo, $fh, $fhht);
		return ($ok, $parents, $go_terms, $assocgenes);
	}

	# disconnect from the database

	$mygo->disconnect;

}

################################
# this routine will fetch genes associated with a 
# go term/name, including all its children
################################

sub get_genes_from_go_term {
	# initialize some global variables
	my $ok = 'yes';
	my @return = ();
	my @goacc = ();
	my @acc_names;
	my @parent_acc_names;
	my @assocgenes;
	
	# in goes the go name/term, and the mygo/DBI object

	my ($name, $mygo, $fh, $fhht)=@_;
	
	# define the mysql query and prepare db, and get the go accession

	my $query = "select acc from term where name = '$name'";
	my $sql = $mygo->prepare($query);
	$sql->execute();
	my $acc;
	while (my $row = $sql->fetchrow_arrayref) {
		$acc = join("\t", @$row);
	}
	
	# conditional to check whether the query has yielded a go accession

	if ($acc){
		
		# if there is a go accession, get child terms
		@goacc = get_child_terms($acc,$mygo);
		push (@goacc, $acc);
		@goacc = unique_array_elements(@goacc);
		
		@acc_names = get_complete_go_info(\@goacc,$acc,$mygo);
		my @parents = get_parent_terms($acc,$mygo);
		@parent_acc_names = get_complete_go_info (\@parents,$acc, $mygo);
		@assocgenes = get_associations(@goacc);
		
	}
		
	else {
		# if we get here, no accession has been found; warn, find suggestions (if any) and return a 'no' value
		print "GO name $name does not exist!\nDid you perhaps mean:\n";
		print $fh "GO name $name does not exist!\nDid you perhaps mean:\n";
		print $fhht "GO name $name does not exist!\n<br>Did you perhaps mean:<br>\n";

		$query = "select acc,name from term where name like '\%$name%'";
		$sql = $mygo->prepare($query);
		$sql->execute();
		my $suggestion;
		while (my $row = $sql->fetchrow_arrayref) {
			
			$suggestion = join("\t", @$row);
			print $suggestion."\n";
			
		}
		if ($suggestion) {
			print "\nplease try again based on named suggestions\n\n";
			print $fh "\nplease try again based on named suggestions\n\n";
			print $fhht "\n<br>please try again based on named suggestions<br><br>\n\n";
		}
		else {
			print "\nSorry: no suggestions fournd.\nplease try again with fewer search terms\n\n";
			print $fh "\nSorry: no suggestions fournd.\nplease try again with fewer search terms\n\n";
			print $fhht "\n<br>Sorry: no suggestions fournd.\nplease try again with fewer search terms<br><br>\n\n";
		}
		$ok = 'no';

	}
	return ($ok,\@parent_acc_names,\@acc_names,\@assocgenes);
	
}
################################
# this routine will fetch genes associated with a 
# go accession, including all its children
################################


sub get_genes_from_go_acc {
	my ($input_acc, $mygo, $fh, $fhht)=@_;
	my $ok = 'yes';

	my @return = ();
	my @goacc = ();
	my @acc_names;
	my @parent_acc_names;
	my @assocgenes;


	my $query = "select acc from term where acc = '$input_acc'";
	my $sql = $mygo->prepare($query);
	$sql->execute();
	my $acc;
	while (my $row = $sql->fetchrow_arrayref) {
		$acc = join("\t", @$row);
	}

	if ($acc){
		# get all child terms
		@goacc = get_child_terms($acc,$mygo);
		push (@goacc, $acc);
		@goacc = unique_array_elements(@goacc);
		# get also distances, go names
		@acc_names = get_complete_go_info(\@goacc,$acc,$mygo);
		# get parent terms
		my @parents = get_parent_terms($acc,$mygo);
		# and also get distances, go names
		@parent_acc_names = get_complete_go_info (\@parents,$acc, $mygo);
		# get gene associations for all the child terms
		@assocgenes = get_associations(@goacc);
		
	}
		
	else {
		# if we get here, no accession has been found; warn and return a 'no' value
		print "GO accession $input_acc does not exist!\n";
		print $fh "GO accession $input_acc does not exist!\n";
		print $fhht "GO accession $input_acc does not exist!<br>\n";
		
		print "\nplease check your GO accession and try again. \nAlternatively try entering a go name.\n\n";
		print $fh "\nplease check your GO accession and try again. \nAlternatively try entering a go name.\n\n";
		print $fhht "<br>\nplease check your GO accession and try again. \nAlternatively try entering a go name.<br><br>\n\n";
		$ok = 'no';

	}
	return ($ok,\@parent_acc_names,\@acc_names,\@assocgenes);
}

###########################
# this routine will fetch all the child terms of a go accession
# it will return only accessions which are annotated with human genes
###########################

sub get_child_terms {
	
	my @goacc=();
	my ($acc,$mygo)=@_;
		
	my $query = "select rchild.name,rchild.acc from term as rchild, term as ancestor, graph_path where graph_path.term2_id = rchild.id and graph_path.term1_id = ancestor.id and ancestor.acc = '$acc'";

	my $sql = $mygo->prepare($query);
	$sql->execute();
		
	while (my $row = $sql->fetchrow_arrayref) {
		my $goterms = join("\t", @$row);
		my @int = split("\t",$goterms);
		my @is_human = is_human($int[1]);
		if (@is_human){
			push (@goacc , $int[1]);
		}	
		#push (@return , $goterms); 
	}
	@goacc = unique_array_elements(@goacc);

	return @goacc;
}

###############################
# this routine will give all the parent terms 
###############################

sub get_parent_terms {
	my @goacc=();
	my ($acc,$mygo)=@_;

	my $query = "select p.name,p.acc from graph_path inner join term as t on (t.id = graph_path.term2_id) inner join term as p on (p.id = graph_path.term1_id) where t.acc = '$acc'";
	
	my $sql = $mygo->prepare($query);
	$sql->execute();
		
	while (my $row = $sql->fetchrow_arrayref) {
		my $goterms = join("\t", @$row);
		my @int = split("\t",$goterms);
		push (@goacc , $int[1]);
			
		
	}
	@goacc = unique_array_elements(@goacc);
	
	return @goacc;
}

###################################
# this routine gives the distance between two go terms
###################################
sub get_distance {
	my ($acc,$goacc,$mygo)=@_;

	my $query = "SELECT min(graph_path1.distance + graph_path2.distance) AS dist FROM graph_path AS graph_path1, graph_path AS graph_path2, term AS t1, term AS t2 WHERE t1.acc = '$acc' and t2.acc = '$goacc' and graph_path1.term2_id = t1.id   and graph_path2.term2_id = t2.id and graph_path1.term1_id = graph_path2.term1_id;
";
	
	my $sql = $mygo->prepare($query);
	$sql->execute();
	my $dist;	
	while (my $row = $sql->fetchrow_arrayref) {
		$dist= join("\t", @$row);
		
	}
	
	return $dist;
}

#####################################
# this routine gives the genes that are annotated with 
# a go terms, FROM THE KVL DB!!! (not from mygo db).
#####################################
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
#####################################
# this sub returns an array with unique elements
#####################################
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
#####################################
# this routine checks whether HUMAN genes are 
# annotated with a go term
#####################################
sub is_human{
	my $database = 'kvl';
	my $server = 'localhost';
	my $user = 'anonymous';
	my $kvl = DBI->connect("dbi:mysql:$database:$server", $user);
	my ($goacc) = @_;
	my @genes;
	my $query = "select entrez_gene_id from go_ncbi where go_term_id = '$goacc'"; 
	my $sql = $kvl->prepare($query);
	$sql->execute();
		
	while (my $row = $sql->fetchrow_arrayref) {
		my $gene = join("\t", @$row);
		push (@genes , $gene); 	
			
	}
	return @genes;
	$kvl->disconnect;
}
###################################
# this sub returns distance search term, the 
# the go accession and the full name
###################################
sub get_complete_go_info {
	
	my ($intgoacc,$acc,$mygo)=@_;
	my @goacc = @$intgoacc;
	my @acc_names;
	foreach my $element (@goacc){
		#print "$element\n";
		my $query = "select acc,name from term where acc = '$element'";
		my $sql = $mygo->prepare($query);
		$sql->execute();
		while (my $row = $sql->fetchrow_arrayref) {
			my $acc_name = join("\t", @$row);
			my $dist = get_distance($element,$acc,$mygo);
			$acc_name = $dist . "\t" . $acc_name ;
			push (@acc_names, $acc_name);
			#print "$acc_name\n";
		}
	}
	return @acc_names;
}

1;
