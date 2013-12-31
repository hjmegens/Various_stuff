#!/usr/bin/perl -w
use CGI ':standard';
use CGI::Carp qw(fatalsToBrowser); 

my $files_location; 
my $ID; 
my @fileholder;
my $folder = param('rn');

$files_location = "/var/tmp/kvltemp/kvltemp$folder";
open (LOG, ">$files_location/errorlog/downloaderror.txt") || Error('open', 'file', $files_location);
#print LOG "$ID\n";
#close (LOG);

print LOG $files_location."\n";
#my $file = "results$folder.tar.gz";
my $file = "results$folder.zip";
#my $output = `tar -czvf $files_location/temp/$file $files_location/results/`;
my $output = `zip $files_location/temp/$file $files_location/results/*`;
print LOG $output."\n";
#Error($output);
print LOG $output."\n";
#if ($ID eq '') { 
#print "Content-type: text/html\n\n"; 
#print "You must specify a file to download."; 
#} else {

open(DLFILE, "<$files_location/temp/$file") || Error('open', 'file',"$files_location/temp/$file" ); 
@fileholder = <DLFILE>; 
close (DLFILE) || Error ('close', 'file'); 


print "Content-Type:application/x-download\n"; 
print "Content-Disposition:attachment;filename=$file\n\n";
print @fileholder;
#}

sub Error {
      print "Content-type: text/html\n\n";
	print "The server can't $_[0] the $_[1]: $_[2] $! \n";
	exit;
}
