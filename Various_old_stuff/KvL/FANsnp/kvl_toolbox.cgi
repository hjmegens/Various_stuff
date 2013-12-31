#!/usr/bin/perl
use strict;
use warnings;
my $baselib = '/usr/local/lib';
use lib "/usr/local/lib/kvl_lib/EnsEMBL48/ensembl/modules/";
use lib "/usr/local/lib/kvl_lib/EnsEMBL48/ensembl-variation/modules/";
use lib "/usr/local/lib/kvl_lib/EnsEMBL48/ensembl-compara/modules/";
use lib "/usr/local/lib/kvl_lib/EnsEMBL48/bioperl-live/";
use DBI;
use CGI ':standard','-debug';
use File::Temp qw/ tempfile /;
use CGI::Carp qw(fatalsToBrowser); 
use Fcntl qw(:flock);
use lib "/usr/local/lib/kvl_lib/KvL";
use Expression;
use File::Basename;
my $basedir = '/var/tmp/kvltemp';
$| = 1; #Turn on autoflush
my $gensearchlimit = 3;
print header;
my $description = param('description');
if ($description){
	print start_html("kvl_toolbox_$description");
}
else {
	print start_html("kvl_toolbox");
}

my $http_agent = $ENV{HTTP_USER_AGENT};
unless ($http_agent =~ /Mozilla/){
	print '<h3>You appear to not be using Mozilla FireFox!</h3>';
	print 'Using Mozilla Firefox is highly recommended for correct display of output!'."<br>$http_agent <hr>\n";
}

print '<h1> FAnSnIP</h1><h3> Functional Animal SNP identification Program, <a href="http://scomp1038.wur.nl/KvL-toolbox-documentation.html" target = "_blank">version 0.96.0</a></h3>'."\n";
print '<hr>';
#do_work();
#print '<hr>';
#
if (param('killjob')){
	if (param('jobid')){
		my $jobid = param('jobid');
		if (param('remoteuser') eq $ENV{REMOTE_USER}){
			if (kill 0 => $jobid){
				#print "$jobid is still alive!<hr>\n";
				print '<META HTTP-EQUIV="Refresh"CONTENT="1; URL=kvl_toolbox.cgi">';
				`kill $jobid`;

			}
		}
		else {
			print "You do not have the authority to kill other processes than your own!!!<br>\n";
		}
	}
}

if (param('rn')){
	#print '<hr>';
	my $rn = param('rn');
	print start_form;
	my $path = $basedir.'/kvltemp'.param('rn').'/results/';
	my $tempdir = $basedir.'/kvltemp'.param('rn');
	my $gensearchfile = $path.'gensearch.html';
	my $genesfile = $path.'genes.txt';
	my $fullreportfile = $path.'fullreport.html';
	my $genesfilepresent =stat($genesfile);
	my $url_snpsearch = 'kvl_toolbox.cgi?rn='.$rn.'&snpsearch=yes&description='.$description;
	my $url_gensearch = 'kvl_toolbox.cgi?rn='.$rn.'&description='.$description;
	if (param('killjob')){
		#kill process
	}	
	if (param('snpsearch')){
		check_pid_running($rn,$url_snpsearch,'b');
		print 'reference: <a href="'.$url_snpsearch.'">snpsearch</a><br>';
		my $string = `cat $fullreportfile`;

		$string =~ s/<html><head><title>.*<\/head><body>//;
		$string =~ s/<\/body><\/html>//;


		print '<a href="download.cgi?rn='.$rn.'">Download Files</a><br><br>';
		print 'please bookmark the current <a href="'.$url_snpsearch.'">webpage</a>, 
			or you may not be able to retreive your results'.' <a href="http://scomp1038.wur.nl/kvldocs_makebookmarks.html" target = "_blank">(?)</a>'.'<br>';
		my $pid = check_PID($tempdir,'SNPSearch');
		#print "PID $pid for tempdir $tempdir <br>"; #comment out in release version
		if ($string){
			print $string;
		}
		else {
			print "<strong> please be patient, results are being generated!</strong> (may take a few minutes)<br>";

			#check_pid_running($rn,$url_snpsearch,'b');
		}

		print '<META HTTP-EQUIV="Refresh"CONTENT="30; URL='.$url_snpsearch.'">';


	}
	elsif (param('Actie')){
		my $remote_user = $ENV{REMOTE_USER};
		if (!$remote_user){
			$remote_user = 'unknown';
		}

		my $output = `/usr/local/bin/KvL -m b -s silent -r $remote_user -t $tempdir 2>$basedir/error2$rn.txt 1>$basedir/stdout2$rn.txt &`;
		print '<strong>Your SNPsearch has been submitted</strong><br> 
			you will be automatically redirected to the results page<br>';
		print '<META HTTP-EQUIV="Refresh"CONTENT="15; URL='.$url_snpsearch.'">';


	}

	elsif ($genesfilepresent){

		my $string = `cat $gensearchfile`;
		$string =~ s/<html><head><title>.*<\/head><body>//;
		$string =~ s/<\/body><\/html>//;

		print $string;
		open (GENES, $genesfile) or warn "cannot open $genesfile: $!";
		my @genes = <GENES>;
		close (GENES);
		my $firstline = shift(@genes);
		my $secondline = shift(@genes);
		my $firstgene = $genes[0];
		chomp $firstgene;
		if (check_numpids('user','b') >= 2){
			print "You have exceeded the limit for submitting SNPsearches!<br>\n";
			print "Make sure you have bookmarked the current page.<br>\n";
			print "Return to this page later and try again!".' <a href="http://scomp1038.wur.nl/kvldocs_filteringoptions.html" target = "_blank">(?)</a>'."<br>";
		}
		if ($firstgene eq 'nogene'){
			print "Your query did not result in any genes being select.<br>You can push the button to start a new query.".' <a href="http://scomp1038.wur.nl/kvldocs_noresults.html" target = "_blank">(?)</a>'."<br>";
			print submit('Action','NEW');
		}
		elsif (param('Select')){
			my @genes_selection = param('gene');
			if (@genes_selection){
				open (GENES, ">$genesfile") or warn "cannot open $genesfile: $!";
				print GENES $firstline.$secondline;
				foreach my $selectgene (@genes_selection){
					print GENES $selectgene."\n";
				}
				close (GENES);
				print '<META HTTP-EQUIV="Refresh"CONTENT="1; URL='.$url_gensearch.'&Actie=Submit">';
			}
			else {
				print '<META HTTP-EQUIV="Refresh"CONTENT="1; URL='.$url_gensearch.'&Select_from_unchecked=AGAIN">';
			}
		}
		elsif (param('Select_from_checked')){

			foreach my $selectgene (@genes){
		
				print '<input type="checkbox" name="gene" value="'.$selectgene.'" checked>'.$selectgene.'<br>';
			}
			#print checkbox_group(
                  	#	-name=>'tissue',
                  	#	-values=>[@genes]);

			print hidden('rn', $rn);
			print hidden('description',$description);
			print submit('Select_from_unchecked','Unmark all');
			print submit('Select','Submit selection');

			print 'reference: <a href="'.$url_gensearch.'">gensearch</a><br>';
			print '<a href="download.cgi?rn='.$rn.'">Download Files</a><br><br>';

			print 'please bookmark the current <a href="'.$url_gensearch.'">webpage</a>, 
				or you may not be able to retreive your results'.' <a href="http://scomp1038.wur.nl/kvldocs_makebookmarks.html" target = "_blank">(?)</a>'.'<br>';


		}

		elsif (param('Select_from_unchecked')){

			foreach my $selectgene (@genes){
		
				print '<input type="checkbox" name="gene" value="'.$selectgene.'">'.$selectgene.'<br>';
			}
			#print checkbox_group(
                  	#	-name=>'tissue',
                  	#	-values=>[@genes]);

			print hidden('rn', $rn);
			print hidden('description',$description);
			print submit('Select','Submit selection');
			print submit('Select_from_checked','Mark all');

			print 'reference: <a href="'.$url_snpsearch.'">gensearch</a><br>';
			print '<a href="download.cgi?rn='.$rn.'">Download Files</a><br><br>';

			print 'please bookmark the current <a href="'.$url_gensearch.'">webpage</a>, 
				or you may not be able to retreive your results<br>';


		}
		else {
			print hidden('rn', $rn);
			print hidden('description',$description);
			print submit('Actie','Submit all genes');
			print submit('Select_from_unchecked', 'Make selection');
			print 'reference: <a href="'.$url_snpsearch.'">gensearch</a><br>';
			print '<a href="download.cgi?rn='.$rn.'">Download Files</a><br><br>';

			print 'please bookmark the current <a href="'.$url_gensearch.'">webpage</a>, 
				or you may not be able to retreive your results<br>';

		}
	}
	else {
		my $string = `cat $gensearchfile`;
		if ($string){
			check_pid_running($rn,$url_gensearch,'a');
			$string =~ s/<html><head><title>.*<\/head><body>//;
			$string =~ s/<\/body><\/html>//;
			
			print $string;
		}
		else {	
			print "<strong> please be patient, results are being generated!</strong><br>";
			check_pid_running($rn,$url_gensearch,'a');
		}

		print '<br><strong>Your gensearch job has been submitted.</strong> <br>';
		print 'please bookmark the current <a href="'.$url_gensearch.'">webpage</a>, 
			or you may not be able to retreive your results<br>';
		print '<META HTTP-EQUIV="Refresh"CONTENT="15; URL='.$url_gensearch.'">';


	}	
	print endform;
}

elsif (param('gene_name')){
	do_gene_name();
}
elsif (param('gene_file')){
	do_gene_list();
}
elsif (param('go_term')){
	do_go_term();
}
elsif (param('gene_name_network')){
	do_gene_network();
}
elsif (param('pubmed')){
	do_pubmed();
}
elsif (param('omim')){
	do_omim();
}
elsif (param('chromosome') && param('region_start') && param('region_end')){
	do_qtl();
}
elsif (param('gene1') && param('gene2')){
	do_intersect();
}
elsif (param('tissue') && param('tpm')){
	do_expression();
}

else {
       	print_prompt();
	get_init_values();
}       
print_tail();
        
print end_html;

sub print_prompt {
	my $gensearchlimit2;
	print start_form;
	
	print "\n<p><em>For which species do you want to find genes?</em>".' <a href="http://scomp1038.wur.nl/kvldocs_species.html" target = "_blank">(?)</a>'."<br>\n",
       	radio_group(
               	-name=>'species',
		-values=>['chicken',
			'cattle',
			'pig',
			'human', 
			'house mouse', 
			'dog',
			'zebrafish'],
		-linebreak=>'yes',
		-default=>'chicken');
	
	print "\n<p><em>How do you want to find your genes?</em>".' <a href="http://scomp1038.wur.nl/kvldocs_searchoptions.html" target = "_blank">(?)</a>'."<br>\n",
                radio_group(
                       -name=>'method',
                       -values=>['Single gene name',
				'List from textfile',
				'QTL region',
				'GO term',
				'PubMed search', 
				'OMIM search', 
				'Gene Network Neighborhood',
				'Intersecting Networks', 
				'Gene Expression'],
			-linebreak=>'yes',
                        -default=>'Single gene name');
	
	unless (param('species')){
		print "<p><em>Filtering options (where applicable):</em>".' <a href="http://scomp1038.wur.nl/kvldocs_filteringoptions.html" target = "_blank">(?)</a>'."<br>";
        	print checkbox_group(
                  -name=>'filtering',
                  -values=>['tissue expression','Gene Set Enrichment - GO','Filter list']);
		print '<br>'."\n";
		if (check_numpids('user','a') <$gensearchlimit){
	        	print submit('Action','Submit');
		}
		else {
			print "you are already running $gensearchlimit GenSearch jobs<br>";
			print "starting a GenSearch at this time would push you over your limit<br>";
			print "TRY AGAIN LATER, or kill one of your jobs".' <a href="http://scomp1038.wur.nl/kvldocs_toomanygensearch.html" target = "_blank">(?)</a>'."<br>\n";
		}
           	print endform;
	}
	#print "<hr>\n";
	
}

sub get_init_values {
	my @values = param('species');
	my $species = join ("",@values);
	@values = param('method');
	my $method = join ("",@values);
	my @secondparams;
	if ($method eq 'Single gene name'){
		@secondparams = ask_hugo_gene();
           		
     	}
	if ($method eq 'QTL region'){
		ask_qtl_region();
            		
      	}
	if ($method eq 'GO term'){
		ask_go_term();
            		
      	}
	if ($method eq 'PubMed search'){
		ask_pubmed_search();
            		
      	}	
	if ($method eq 'OMIM search'){
		ask_omim();
            		
      	}
	if ($method eq 'Gene Network Neighborhood'){
		ask_gene_network_neighborhood();
            		
      	}
	if ($method eq 'Intersecting Networks'){
		ask_insecting_networks();
            		
      	}
	if ($method eq 'Gene Expression'){
		ask_gene_expression();
            		
      	}
	if ($method eq 'List from textfile'){
		ask_gene_list();
            		
      	}

}

sub do_work {
	my(@values,$key);

	#print "<h2>Here are the current settings in this form</h2>";

	foreach $key (param) {
              print "<strong>$key</strong> -> ";
              @values = param($key);
              print join(", ",@values),"<br>\n";
	}
}

sub print_tail {
	print '<hr>';
	display_jobs();
	print start_form,
        	"<hr>This is a work in progress. Bugs of any kind, including crashes
 		and errors in the output are to be expected at this stage. <br> By 
 		testing you help develop the toolbox further!<br>
 		Report errors or remarks to: <a href=/>Hendrik-Jan Megens</a><br>",
		p,
		'<hr>"Kwaliteit van Leven" is a collaborative project of Wageningen University Animal 
		Breeding and Genomics Centre (ABGC), <br>Institute for Pig Genetics (IPG), Holland 
		Genetics and Hendrix Genetics, and is sponsored by SenterNovem',
		p,	
		"<hr>",
	end_form;

}
sub ask_hugo_gene {
	print start_form;
        print "<em>Which gene do you want to retrieve? ".' <a href="http://scomp1038.wur.nl/kvldocs_gene.html" target = "_blank">(?)</a>'." (example: IGF1)?</em><br>";
        print textfield('gene_name');
	print "<p>",reset;
        print submit('Action','Submit');
        print endform;
	#print "<hr>\n";
	my @values = param('gene_name');
			
}
sub ask_gene_list {
	print start_form;
        #print '<form action="upload.cgi" method="post"  
	#	enctype="multipart/form-data">
	print  	'<p>File to Upload: <input type="file" name="gene_file" /></p>
		<p><input type="submit" name="Submit" value="Submit Gene List" /><a href="http://scomp1038.wur.nl/kvldocs_genelist.html" target = "_blank">(?)</a></p>';
	
		print '<br>';
	ask_filtering();
	
        print endform;
			
}

sub ask_qtl_region {
	print start_form;
        print "<em>What chromosomal or qtl region do you want to query?".' <a href="http://scomp1038.wur.nl/kvldocs_qtlregion.html" target = "_blank">(?)</a>'."<br>
 		Name of chromosome (example: 1)?</em><br>";
        print textfield('chromosome');
	print "<br><em>start of region in bp (example: 56000000)</em><br>";
        print textfield('region_start');
	print "<br><em>end of region in bp (example: 59000000)</em><br>";
        print textfield('region_end');

	ask_filtering();
	
		print '<br>';
        print submit('Action','Submit');
        print endform;
	#print "<hr>\n";
}

sub ask_go_term {
	print start_form;
        print "<em>For which GO term (accession or name) would you like to retrieve associated genes?".' <a href="http://scomp1038.wur.nl/kvldocs_go.html" target = "_blank">(?)</a>'."<br>
	(example: either 'GO:0040007' OR 'growth')</em><br>";
        print textarea(-name=>'go_term',
                                  -rows=>1,
                                  -columns=>50);

	ask_filtering();
	
		print '<br>';
        print submit('Action','Submit');
        print endform;
	#print "<hr>\n";
}

sub ask_pubmed_search {
	#limit number of pubmed searches;
	my $numpubmedsearches = check_numpids('pubmed','a');
	if ($numpubmedsearches < 3){
		
		print start_form;
	        print "<em>Find genes based on pubmed search".' <a href="http://scomp1038.wur.nl/kvldocs_pubmed.html" target = "_blank">(?)</a>'."<br>\n(example: fertility and female and gene and mutation and human and cause)</em><br>";
	        print textarea(-name=>'pubmed',
	                                  -rows=>1,
	                                  -columns=>50);
	
		ask_filtering();
		print '<br>';
	        print submit('Action','Submit');
	        print endform;
		#print "<hr>\n";
	}
	else {
		print "The maximum number of PubMed searches is reached<br>";
		print "Please try again later!<br>\n";
	}
}
sub ask_omim {
	print start_form;
	print "<em>Find genes based on OMIM search".' <a href="http://scomp1038.wur.nl/kvldocs_omim.html" target = "_blank">(?)</a>'."<br>\n(example: fertility and female)</em><br>";
	print textarea(-name=>'omim',
	         -rows=>1,
	         -columns=>50);
	
	ask_filtering();
	print '<br>';
	print submit('Action','Submit');
	print endform;
}

sub ask_gene_network_neighborhood {
	print start_form;
        print "<em>Input a gene for which to build a network neighborhood".' <a href="http://scomp1038.wur.nl/kvldocs_genenetwork.html" target = "_blank">(?)</a>'."<br>example: IGF2</em><br>";
        print textfield('gene_name_network'); 
	print '<br><em>Depth: </em>';
	print radio_group(
                        -name=>'depth',
                        -values=>[0,1,2,3,4],
                        -default=>1);

	ask_filtering();
		print '<br>';
        print submit('Action','Submit');
	
        print endform;
	#print "<hr>\n";
}


sub ask_insecting_networks {
	print start_form;
        print "<em><strong>Input two genes that are starting points for building networks:</strong>".' <a href="http://scomp1038.wur.nl/kvldocs_intergenenet.html" target = "_blank">(?)</a>'."<br>Gene 1:<br>\nWhich gene (HGCN) do you want to retrieve? (example: ESR2) </em><br>";
        print textfield('gene1');
 	print '<br>';
	print "<em>Gene 2:<br>\nWhich gene (HGCN) do you want to retrieve? (example: GH1) </em><br>";
        print textfield('gene2');
	print '<br><em>Depth: </em>';
	print radio_group(
                        -name=>'depth',
                        -values=>[0,1,2,3,4],
                        -default=>1);

	print '<br>';

	ask_filtering();
	
		print '<br>';
        print submit('Action','Submit');
        print endform;
	#print "<hr>\n";
}
sub ask_gene_expression {
	print start_form;
        print "<em><strong>Select one or more tissues from the list below:</strong>".' <a href="http://scomp1038.wur.nl/kvldocs_expression.html" target = "_blank">(?)</a>'."<br> </em>";
	my $species_e = Expression::species(param('species'));
	my @tissues = Expression::tissue_list($species_e) ;
	print checkbox_group(
                  -name=>'tissue',
                  -values=>[@tissues]);

	print "<p><em>What expression level (Transcripts Per Million - TPM)?</em><br>";
	print radio_group(
                        -name=>'tpm',
                        -values=>[10,100,1000],
                        -default=>1000);
	print "<p><em>In case of multiple tissues, how do you want to combine:</em><br>";
	print radio_group(
                        -name=>'conditional',
                        -values=>['AND','OR','NOT'],
                        -default=>'AND');

	print '<br>';
	ask_filtering();
		print '<br>';
        print submit('Action','Submit');
        print endform;
	#print "<hr>\n";
}
sub ask_gene_expression_filtering {
        print "<br><br><em><strong>Select one or more tissues from the list below:</strong>".' <a href="http://scomp1038.wur.nl/kvldocs_filteringoptions.html" target = "_blank">(?)</a>'."<br> </em>";
	my $species_e = Expression::species(param('species'));
	my @tissues = Expression::tissue_list($species_e) ;
	print checkbox_group(
                  -name=>'tissue',
                  -values=>[@tissues]);

	print "<p><em>What expression level (Transcripts Per Million - TPM)?</em><br>";
	print radio_group(
                        -name=>'tpm',
                        -values=>[10,100,1000],
                        -default=>1000);
	print "<p><em>In case of multiple tissues, how do you want to combine:</em><br>";
	print radio_group(
                        -name=>'conditional',
                        -values=>['AND','OR','NOT'],
                        -default=>'AND');

	print '<br>';
	#print "<hr>\n";
}

sub check_species {
	my ($species) = @_;
	if ($species eq 'chicken') {
		$species = '1';
	}
	if ($species eq 'cattle') {
		$species = '2';
	}
	if ($species eq 'pig') {
		$species = '3';
	}
	if ($species eq 'human') {
		$species = '4';
	}
	if ($species eq 'house mouse') {
		$species = '5';
	}
	if ($species eq 'dog') {
		$species = '6';
	}
	if ($species eq 'zebrafish') {
		$species = '7';
	}

	return $species;
}

sub check_method {
	my ($what) = @_;
	if ($what eq 'Single gene name'){
		$what = '1' ;
	}
	if ($what eq 'QTL region'){
		$what = '2';
	}
	if ($what eq 'GO term'){
		$what = '3';
	}
	if ($what eq 'PubMed search'){
		$what = '4';
	}
	if ($what eq 'OMIM search'){
		$what = '5';
	}
	if ($what eq 'List from textfile'){
		$what = '6';
	}
	if ($what eq  'EnsEMBL stable gene id'){
		$what = '7';
	}
	if ($what eq 'Gene Network Neighborhood'){
		$what = '8';
	}
	if ($what eq 'Intersecting Networks'){
		$what = '9';
	}
	if ($what eq 'Gene Expression'){
		$what = '10';
	}

	return $what;
}
sub do_gene_name {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	print $argfh $species."\n".$method."\n".param('gene_name')."\n\n\n";
	close ($argfh);
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;
	
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);
	
	#print "guest name: $ENV{REMOTE_USER} <br>browser: $ENV{HTTP_USER_AGENT}<br>";
	my $description_int = param('species')."_".param('method')."_".param('gene_name');
	print_gensearch_redirection_form($rn,$description_int);
}

sub do_gene_list {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	my $filename = param("gene_file");
	my $ctype = uploadInfo($filename)->{'Content-Type'};
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;
	
	my $expressionfiltering = process_filtering_options($basedir,$rn);
	
		my $safe_filename_characters = "a-zA-Z0-9_.-";
	#my $newfilename = "genelist".param('rn');
	my $newfilename = "genelist$rn";
	#my $filename = param("filename");

	my $orig_filename = $filename;
	if ( !$filename ){
		 print header ( );
		 #print $query->header ( );
		 print "There was a problem uploading your file (try a smaller file).";
		 exit;
	}
	print "your gene list is in the file: <strong> $orig_filename </strong><br>";
	print "type is: $ctype <br>\n";
	my ( $name, $path2, $extension ) = fileparse ( $filename, '\..*' );
	$filename = $name . $extension;
	$filename =~ tr/ /_/;
	$filename =~ s/[^$safe_filename_characters]//g;
	
	if ( $filename =~ /^([$safe_filename_characters]+)$/ ){
		 $filename = $1;
	}
	else{
		 die "Filename contains invalid characters";
	}
	if ( $ctype !~ /text/ ){
		 die "NOT a text file";
	}


	#my $query = new CGI;
	#$CGI::POST_MAX = 100 * 100;

	#my $upload_filehandle = $query->upload("gene_file");

	#open ( UPLOADFILE, ">$basedir/$newfilename" ) or die "$!";
	#binmode UPLOADFILE;

	#while ( <$upload_filehandle> ){
	#	 print UPLOADFILE;
	#}	

	open ( UPLOADFILE, ">$basedir/$newfilename" ) or die "$!";
	flock(UPLOADFILE, LOCK_EX);
	my $file_len = 0;
	while (read ($orig_filename, my $i, 1024)){
		print UPLOADFILE $i;
		$file_len = $file_len + 1024;
		if ($file_len > 102400){
			close (UPLOADFILE);
			die "File TOO LARGE, upload aborted";
		}
	}
	
	close UPLOADFILE;
	print "File size: ".($file_len/1024)."KB<br>\n";
	`dos2unix $basedir/$newfilename`;
	print $argfh $species."\n".$method."\n".$expressionfiltering."\n$basedir/$newfilename"."\n\n\n";
	close ($argfh);
	
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);

	my $description_int = param('species')."_".param('method')."_".param('gene_file');
	print_gensearch_redirection_form($rn,$description_int);
}

sub do_go_term {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;

	my $expressionfiltering = process_filtering_options($basedir,$rn);

	print $argfh $species."\n".$method."\n".$expressionfiltering."\n".param('go_term')."\n\n\n";
	close ($argfh);
	
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);

	my $description_int = param('species')."_".param('method')."_".param('go_term');
	print_gensearch_redirection_form($rn,$description_int);
}

sub do_pubmed {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = '/var/tmp/kvltemp/kvltemp';
	$rn =~ s/$path//g;

	my $expressionfiltering = process_filtering_options($basedir,$rn);

	print $argfh $species."\n".$method."\n".$expressionfiltering."\n".param('pubmed')."\n\n\n";
	close ($argfh);
		
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn,'pubmed');

	my $description_int = param('species')."_".param('method')."_".param('pubmed');
	print_gensearch_redirection_form($rn,$description_int);
}

sub do_omim {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = '/var/tmp/kvltemp/kvltemp';
	$rn =~ s/$path//g;

	my $expressionfiltering = process_filtering_options($basedir,$rn);

	print $argfh $species."\n".$method."\n".$expressionfiltering."\n".param('omim')."\n\n\n";
	close ($argfh);
		
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);

	my $description_int = param('species')."_".param('method')."_".param('omim');
	print_gensearch_redirection_form($rn,$description_int);
}

sub do_gene_network {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;

	my $expressionfiltering = process_filtering_options($basedir,$rn);

	print $argfh $species."\n".$method."\n".$expressionfiltering."\n".param('gene_name_network')."\n".param('depth')."\n\n\n";
	close ($argfh);

	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);

	my $description_int = param('species')."_".param('method')."_".param('gene_name_network')."_depth".param('depth');
	print_gensearch_redirection_form($rn,$description_int);
}
sub do_qtl {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;

	my $expressionfiltering = process_filtering_options($basedir,$rn);

	print $argfh $species."\n".$method."\n".$expressionfiltering."\n".param('chromosome')."\n".param('region_start')."\n".param('region_end')."\n\n\n";
	close ($argfh);
	
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);

	my $description_int = param('species')."_".param('method')."_chrom".param('chromosome')."_start".param('region_start')."_end".param('region_end');
	print_gensearch_redirection_form($rn,$description_int);

}
sub do_intersect {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));

	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;


	my $expressionfiltering = process_filtering_options($basedir,$rn);
	
	print $argfh $species."\n".$method."\n$expressionfiltering\n".param('gene1')."\n".param('gene2')."\n".param('depth')."\n\n\n";
	close ($argfh);
	
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);
	
	my $description_int = param('species')."_".param('method')."_gene1-".param('gene1')."_gene2-".param('gene2');
	print_gensearch_redirection_form($rn,$description_int);
}
sub do_expression {
	my $basedir = '/var/tmp/kvltemp';
	my ($argfh, $argfilename) = tempfile("$basedir/kvltempXXXXXXXX", SUFFIX => ".args" );
	my $species = check_species(param('species'));
	my $method = check_method(param('method'));
	
	my $tempdir = $argfilename;
	$tempdir =~ s/\.args//g;
	my $rn = $tempdir;
	my $path = $basedir.'/kvltemp';
	$rn =~ s/$path//g;
	
	if (param('filter_file')){
		upload_filter_file($basedir,$rn);
	}

	###############################

	print $argfh $species."\n".$method."\n";
	my @tissues = param('tissue');
	foreach my $tissue (@tissues){
		print $argfh $tissue.',';
	}
	my $conditional = re_conditional(param('conditional'));
	print $argfh "\n".param('tpm')."\n".$conditional."\n\n\n";
	close ($argfh);
	
	submit_gensearch_job($tempdir,$argfilename,$basedir,$rn);
	
	my $description_int = param('species')."_".param('method')."_tissue".param('tissue')."_tpm".param('tpm')."_".param('conditional');
	print_gensearch_redirection_form($rn,$description_int);
}

sub check_PID {
	my ($tempdir,$searchtype)=@_;
	my $PID;
	my $log = `cat /var/tmp/kvllog.txt`;
	my @loglines = split("\n",$log);
	foreach my $logline (@loglines){
		if ($logline =~ /$tempdir/){
			if ($logline =~ /$searchtype/g){

				my @parameters = split("\t",$logline);
				$PID = $parameters[0];
				$PID =~ s/PID: //;
			}
		}
	}
	#met ps|grep
	return $PID;
}

sub re_conditional {
	my ($conditional)=@_;
	if ($conditional eq 'AND'){$conditional =1}		
	if ($conditional eq 'OR'){$conditional =2}		
	if ($conditional eq 'NOT'){$conditional =3}
	return $conditional;
}	

sub ask_filtering {

	my $filteroptionstring = join('-',param('filtering'));
	if ($filteroptionstring =~ /Gene Set Enrichment - GO/){
		print "<p><em>supply a p-value for GO overrepresentation analysis:</em><br>";
		print radio_group(
                        -name=>'pval',
                        -values=>[0.05,0.01,0.001,0.0001,0.00001,0.000001,0.0000001],
                        -default=>0.0001);

		print '<br>';

	}
	
	if ($filteroptionstring =~ /tissue expression/){
		ask_gene_expression_filtering();
	}

	if ($filteroptionstring =~ /Filter list/){
	#print '</form> ';
		print	'<br><p>Filter File to Upload: <input type="file" name="filter_file" /></p>';
		print "<p><em>condition for using the filter file:</em><br>";
		print radio_group(
                        -name=>'filterfilecondition',
                        -values=>['AND','OR','NOT'],
                        -default=>'AND');

		print '<br>';

	#	<p><input type="submit" name="Submit" value="Submit Gene FILTER List" /></p>';
	}
}
sub upload_filter_file {
	my ($upload_dir,$rn) = @_;
	my $filename = param("filter_file");
	my $ctype = uploadInfo($filename)->{'Content-Type'};
	my $newfilename = "filterlist$rn.txt";
	my $orig_filename = $filename;
	$CGI::POST_MAX = 100;
	my $safe_filename_characters = "a-zA-Z0-9_.-";
	#my $newfilename = "genelist".param('rn');

	if ( !$filename )
	{
		 print header ( );
		 #print $query->header ( );
		 print "There was a problem uploading your file (try a smaller file).";
		 exit;
	}
	print "your filter list is in the file: <strong> $orig_filename </strong><br>";
	my ( $name, $path2, $extension ) = fileparse ( $filename, '\..*' );
	$filename = $name . $extension;
	$filename =~ tr/ /_/;
	$filename =~ s/[^$safe_filename_characters]//g;
	
	if ( $filename =~ /^([$safe_filename_characters]+)$/ )
	{
		 $filename = $1;
	}
	else
	{
		 die "Filename contains invalid characters";
	}
	if ( $ctype !~ /text/ ){
		 die "NOT a text file";
	}

	open ( UPLOADFILE, ">$basedir/$newfilename" ) or die "$!";
	flock(UPLOADFILE, LOCK_EX);
	my $file_len = 0;
	while (read ($orig_filename, my $i, 1024)){
		print UPLOADFILE $i;
		$file_len = $file_len + 1024;
		if ($file_len > 102400){
			close (UPLOADFILE);
			die "File TOO LARGE, upload aborted";
		}
	}	

	close UPLOADFILE;
	`dos2unix $upload_dir/$newfilename`;
}
sub submit_gensearch_job {
	my ($tempdir,$argfilename,$basedir,$rn,$comment) = @_; #$comment is not generally applied in calling the sub!!! take care when adding!
	my $remote_user = $ENV{REMOTE_USER};
	if (!$remote_user){
		$remote_user = 'unknown';
	}
	unless ($comment){
		$comment = 'nocomment';
	}
	if (param('pval')){
		my $pval = param('pval');
		if (param('filter_file')){
		
			my $andornot = param('filterfilecondition');
			my $out = `/usr/local/bin/KvL -m a -s silent -r $remote_user -f $pval -c $comment -l $andornot -t $tempdir $argfilename 2>$basedir/error$rn.txt 1>$basedir/stdout$rn.txt &`;
	
		}
		else{
			my $out = `/usr/local/bin/KvL -m a -s silent -r $remote_user -f $pval -c $comment -t $tempdir $argfilename 2>$basedir/error$rn.txt 1>$basedir/stdout$rn.txt &`;
		}
	}
	else {
		if (param('filter_file')){
		
			my $andornot = param('filterfilecondition');
			my $out = `/usr/local/bin/KvL -m a -s silent -r $remote_user -c $comment -l $andornot -t $tempdir $argfilename 2>$basedir/error$rn.txt 1>$basedir/stdout$rn.txt &`;

		}
		else{
			my $out = `/usr/local/bin/KvL -m a -s silent -r $remote_user -c $comment -t $tempdir $argfilename 2>$basedir/error$rn.txt 1>$basedir/stdout$rn.txt &`;
		}
	}
}
sub check_pid_running {
	my ($rn,$url,$searchtype) = @_;
	my $pid;
	my $testpid = `ps -efH | grep apache | grep '/usr/local/bin/KvL -m $searchtype -s silent' | grep $rn`;
	#$testpid =~ s/^apache.*grep//;
	my @testarray = split('apache',$testpid);
	foreach my $testpid2 (@testarray){
		if ($testpid2 =~ /kvltemp\/kvltemp/){
			print "At ".scalar(localtime)." your job is still running!!!!<br>\n";
			print submit('killjob','Kill Job')."<br>\n";
			#print $testpid2."\n";
			print '<br>';
			if ($testpid2 =~ /^ +(\d+) /){
				$pid = $1;
				if ($testpid2 =~ / -r ([a-zA-Z0-9]+) /){
					my $remoteuser = $1;
					print hidden('jobid', $pid);
					print hidden('remoteuser', $remoteuser);
					#print 'process id: '.$pid.'<br>';
				}
			}
		}
	}

	unless ($pid) {
			print "Your job has terminated....<br>\n";
	
	}
}
sub check_numpids {
	my ($search_for,$searchtype) = @_;
	my $searchstring;
	my $numpids;
	if ($search_for eq 'user'){
		$searchstring = $ENV{REMOTE_USER};

	}
	elsif ($search_for eq 'pubmed'){
		$searchstring = 'pubmed';
	}
	if ($searchstring){
		my $testpid = `ps -efH | grep apache | grep '/usr/local/bin/KvL -m $searchtype -s silent' | grep $searchstring`;
		$testpid =~ s/^apache.*grep//;
		if ($testpid =~ /kvltemp\/kvltemp/){
			my @testarray1 = split('-t /var/tmp/kvltemp/kvltemp',$testpid);
			$numpids = scalar(@testarray1)-1;
			#print "Currently ".scalar(localtime)." you have ".(scalar(@testarray1)-1)." processes running<br>";
		}
	}
	return $numpids;
}

sub print_gensearch_redirection_form {
	my ($rn,$description_int) = @_;	
	print start_form;
	print hidden('rn', $rn);
	print hidden('description', $description_int);
	print 'You will be automatically redirected to the results page';
	print '<META HTTP-EQUIV="Refresh"CONTENT="5; URL=kvl_toolbox.cgi?rn='.$rn.'&description='.$description_int.'">';
	print endform;
}

sub process_filtering_options {
	my($basedir,$rn)=@_;
	my $expressionfiltering = 'tissuefiltering=no';
	if (param('tissue')){
		$expressionfiltering = "tissuefiltering=yes#".join(',',param('tissue'))."#".param('tpm')."#".re_conditional(param('conditional'));
	}
	if (param('filter_file')){
		upload_filter_file($basedir,$rn);
	}
	return $expressionfiltering;
}

sub display_jobs {
	my $user = $ENV{REMOTE_USER};

	my $numpids_gensearch = check_numpids('user','a');
	my $numpids_snpsearch = check_numpids('user','b');
	print "At this time ".scalar(localtime)." you ($user) have: <br>\n";
	if ($numpids_gensearch){
		print "GenSearch: $numpids_gensearch jobs running<br>\n";
	}
	else {
		print "GenSearch: no jobs running<br>\n";
	}
	if ($numpids_snpsearch){
		print "SNPSearch: $numpids_snpsearch jobs running<br>\n";
	}
	else{
		print "SNPSearch: no jobs running<br>\n";
	}
}


