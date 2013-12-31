#!/usr/bin/perl -w

use strict;
use CGI ':standard','-debug';
use CGI::Carp qw ( fatalsToBrowser );
use File::Basename;

$CGI::POST_MAX = 10000;
my $safe_filename_characters = "a-zA-Z0-9_.-";
my $upload_dir = "/var/tmp/kvltemp";
#my $newfilename = "genelist".param('rn');
my $newfilename = "genelist";
print 'where ami?';
my $query = new CGI;
#my $filename = param("filename");
my $filename = $query->param("filename");
if ( !$filename )
{
 #print header ( );
 print $query->header ( );
 print "There was a problem uploading your file (try a smaller file).";
 exit;
}

my ( $name, $path, $extension ) = fileparse ( $filename, '\..*' );
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

#my $upload_filehandle = upload(param("filename"));
my $upload_filehandle = $query->upload("filename");

open ( UPLOADFILE, ">$upload_dir/$newfilename" ) or die "$!";
binmode UPLOADFILE;

while ( <$upload_filehandle> )
{
 print UPLOADFILE;
}

close UPLOADFILE;

