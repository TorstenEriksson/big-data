#!/usr/bin/perl -w
#
# Fetches nucleotide data from genbank and creates a local blast database
# A list of genbank identifiers are expected to be found in the first column of a text file
#
use Bio::Perl;
use Getopt::Long;
#use Data::Dumper;
use strict;

# Get supplied file names
my $contiglist = '';
my $fastafile = '';
my $blastdatabase = '';
my $dryrun = '';
my $verbose = '';
GetOptions (
  "contigs=s" => \$contiglist,    # name of file that lists genbank numbers
  "fasta=s"   => \$fastafile,    # name of fasta file to save nucleotide data in
  "blast=s"  => \$blastdatabase, # name of blast+ (nucleotide) database
  "dry_run" => \$dryrun,   # if set, no data will actually be fetched from genbank (for testing)
  "verbose" => \$verbose   # prints book keeping data if set
  ) or die("Error in command line arguments\n");

if ($contiglist && $fastafile && $blastdatabase) {

  # Get list of all contigs
  open(my $fh, "<", $contiglist) or die "cannot open < $contiglist: $!";
  my @contigs;
  my $prev = '';
  while (<$fh>) {
    if (! /^#/) {
      @_ = split(/\s+/);
      if ($_[0] ne $prev) {
        push @contigs, $_[0];
        $prev = $_[0];
      }
    }
  }
  if ($verbose) {
    print 'Found ', scalar(@contigs), ' contig names in ', $contiglist, "\n";
  }
  close $fh;

  # Get sequence data for all contigs and save to fasta file

  # ** TO DO **
  # Handle errors in some intelligent way
  if (! $dryrun) {
    my @sobs;
    open(my $fh, ">", $fastafile) or die "cannot open > $fastafile: $!";
    for (@contigs) {
      if ($verbose) {
        print "Fetching $_ ...\n";
      }
      my $sob = get_sequence('genbank', $_);
      push @sobs, $sob;
    }
    if ($verbose) {
      print 'Successfully fetched ', scalar(@sobs), ' genbank records', "\n";
      print "Writing fasta file '$fastafile' ...\n";
    }
    write_sequence(">$fastafile", 'fasta', @sobs);
    close $fh;
  }

  # Create a blast database and populate it with the sequences
  if ($verbose) {
    print "Creating blast+ database '", $blastdatabase, "' with data from '", $fastafile, "'\n";
  }
  my $makeblastdb_infotext = 'makeblastdb_createinfo.txt';
  system("makeblastdb -in $fastafile -input_type 'fasta' -dbtype 'nucl' -out $blastdatabase > $makeblastdb_infotext");
  if ($verbose) {
    system("cat $makeblastdb_infotext");
  }
}
else {
  die "Missing file name(s)\n";
}
