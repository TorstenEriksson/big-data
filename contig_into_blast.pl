#!/usr/bin/perl -w
#
# contig_into_blast.pl
# Fetches nucleotide data from genbank and creates a local blast database
# NOTE: The script might attempt to fetch a large amount of data over the internet.
#       It may take a long time.
#
# Input:
#        -contig "contigs_list_file_name"
#         A plain text file of Genbank ids that are fetched in fasta format and saved to a file.
#         The ids are expected to be found in the first column of the file.
#        -fasta "new_file_name"
#         The name of the new file that will contain all sequences in fasta format.
#        -blast "database_file_name"
#         The name of the blast+ database to create. Any old database with this name will be
#         overwritten.
#
# Optional:
#        -verbose
#         This will result in various info being printed along the way.
#        -help
#         Brief usage and version information is printed.
#        -dryrun
#         For testing, no sequences are fetched.
#
# Output: A file with sequence data in fasta format
#         A blast+ nicleotide database
#
# Prerequisites:
#         Bioperl installed
#         NCBI blast program installed
# Warning:
#         There is currently no error handling when downloading sequences. Bioperl exceptions will
#         cause the run to croak.
#
#   Copyright (c) Torsten Eriksson, 2017
# ---------------------------------------------------------------------------
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
# ---------------------------------------------------------------------------
use strict;
use Getopt::Long;
use Date::Format;
use Bio::Perl;

# Version
my $version = '0.2';
my $error = 0;

# Get supplied file names and switches
my $contiglist = 'allcontig.agp';
my $fastafile = '';
my $blastdatabase = '';
my $dryrun = '';
my $verbose = '';
my $help = '';
GetOptions (
  "contigs=s" => \$contiglist,    # name of file that lists genbank numbers
  "fasta=s"   => \$fastafile,    # name of fasta file to save nucleotide data in
  "blast=s"  => \$blastdatabase, # name of blast+ (nucleotide) database
  "dry_run" => \$dryrun,    # if set, no data will actually be fetched from genbank (for testing)
  "verbose" => \$verbose,   # prints book-keeping data if set
  "help" => \$help          # prints usage info
) or die("Error in command line arguments\n");

if ($help) {
  PriUsage();
  exit(0);
}

if ($contiglist && $fastafile && $blastdatabase) {

  # Book-keeping
  if ($verbose) {
    PriVersion();
    my @lt = localtime(time);
    print "Run at:", strftime("Y-m-d H:M:S", @lt), "\n";
  }

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
    open($fh, ">", $fastafile) or die "cannot open > $fastafile: $!";
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
  if (! system("makeblastdb -in $fastafile -input_type 'fasta' -dbtype 'nucl' -out $blastdatabase > $makeblastdb_infotext")) {
    $error = 1;
  }
  if (-e $makeblastdb_infotext) {
    if ($verbose || $error) {
      system("cat $makeblastdb_infotext");
    }
    unlink $makeblastdb_infotext;
  }
}
else {
  die "Missing file name(s)\n";
  PriUsage();
  $error = 1;
}
if ($error) {
  exit(1);
}
exit(0);

sub PriUsage {
  print "\nUsage:\n";
  print "contig_into_blast.pl -contig contigs_list_file_name -fasta new_file_name -blast database_file_name [-verbose] [-help]\n";
  PriVersion();
}

sub PriVersion {

  print "\ncontig_into_blast.pl ver. $version\n";
}