#!/usr/bin/perl -w
#
# Blast some sequences against the Fragaria vesca genome (local blast database)
#
# Before running this, you need:
#   A local blast database [run contig_into_blast.pl]
#   A map file to get genes mapped [mapview/seq_gene.md]
#   NCBI blast+ software installed [https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download]
#   BioPerl installed [Bio::Perl. See http://bioperl.org/howtos/Beginners_HOWTO.html]
#
use Bio::Perl;
use Getopt::Long;
use Date::Format;
use Data::Dumper;
use strict;

my $version = '0.1';
my $local_genome_home = '~/Documents/Forsk/Genome/';
my $genome_folder = $local_genome_home . 'Fragaria_vesca_genome_2017-01-02/';

# Get supplied file names and switches
my $qfile = '';
my $bdb = $local_genome_home . 'fragaria_seq.db';
my $mapfile = $genome_folder . 'mapview/seq_gene.md';
my $evalue = 50;
my $help = '';
GetOptions (
  "query=s"     => \$qfile,    # file containing the sequences you want to blast
  "database=s"  => \$bdb,      # database to blast against [example: fragaria_seq.db]
  "map=s"       => \$mapfile,  # file containing gene mappings [mapview/seq_gene.md]
  "evalue=i"    => \$evalue,   # evalue for the blast run
  "help" => \$help          # prints usage info
) or die("Error in command line arguments\n");

if ($help) {
  PriUsage();
  exit(0);
}

if (! -e $qfile) {
  die("Unable to find query file: $qfile\n");
}

# Blast
my @result = split(/\n/, system("blastn -query $qfile -db $bdb -evalue $evalue -outfmt 6"));
# output format 6 contains as default the columns:
# query acc., subject acc., % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score
# We want sstart & ssend (array index 0, 1, 2, 8, 9)
# Pick up the result
my @blast;
for (@result) {
  chomp();
  @_ = split(/\s+/);
  push (@blast,
    [
    $_[0],  # query accession
    $_[1],  # subject accession [= contig id]
    $_[2],  # % identity
    $_[8],  # subject start
    $_[9],  # subject end
    ]
  );
}

# Read map file (gene feature only)
my $inputfile = $mapfile;
my @map;
open(my $fh, $inputfile) or die "cannot open > $inputfile: $!";
while (<$fh>) {
  if (!/^#/) {
    chomp();
    @_ = split(/\s+/);
    if ($_[11] == 'GENE') {
      push(@map,
        [
        $_[5],  # contig id
        $_[1],  # chromosome
        $_[2],  # start
        $_[3],  # stop
        $_[4],  # orientation
        $_[9],  # feature name
        $_[10], # feature id
        ]
      );
    }
  }
}
close $fh;
# Add map information
for (@blast) {

}

# Output result

exit;
sub PriUsage {
  PriVersion();
  print "Usage:\n";
  print "fraves_blast.pl [-help] -query 'filename' [-database 'database-name'] [-evalue integer] \n";
}

sub PriVersion {
  print "fraves_blast.pl ver. $version\n";
}
