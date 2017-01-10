#!/usr/bin/perl -w
use strict;
use Class::Inspector;
use Data::Dumper;
use Bio::Seq;
use Bio::Perl;
use Bio::SeqIO;
my $curiosity = shift(@ARGV);
if ($curiosity eq "-h") {
  print "USAGE:\n";
  print "classinspector.pl [-h] class_or_module ['full' | 'expanded']\n";
  exit;
}
#use "$curiosity";
my $depth = shift(@ARGV);
my @methods;
if ($depth) {
  @methods =   Class::Inspector->methods( $curiosity, 'public', $depth );
}
else {
  @methods =   Class::Inspector->methods( $curiosity, 'public' );
}
for (@methods) {
  print Dumper(@methods), "\n";
}
exit(0);