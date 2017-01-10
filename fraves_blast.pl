#!/usr/bin/perl -w
#
# Blast some sequences against the Fragaria vesca genome (local blast database)
#
# Before running this, you need:
#   A local blast database [run contig_into_blast.pl]
#   A gene mapping file 'mapview/seq_gene.md' (decompressed) from the genome
#   A map file to get genes mapped [mapview/seq_gene.md]
#   NCBI blast+ software installed [https://blast.ncbi.nlm.nih.gov/Blast.cgi?PAGE_TYPE=BlastDocs&DOC_TYPE=Download]
#   BioPerl installed [Bio::Perl. See http://bioperl.org/howtos/Beginners_HOWTO.html]
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
#
use Getopt::Long;
use strict;

my $version = '0.1';
my $local_genome_home = '/home/ter062/Documents/Forsk/Genome/';
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
my $tmpfile = 'blast_tmp.txt';
system("blastn -query $qfile -db $bdb -evalue $evalue -outfmt 6 > $tmpfile");
# output format 6 contains as default the columns:
# query acc., subject acc., % identity, alignment length, mismatches, gap opens, q. start, q. end, s. start, s. end, evalue, bit score
# We want sstart & ssend (array index 0, 1, 2, 8, 9)

# Pick up the blast results
my @blast;
my $fh;
open($fh, $tmpfile) or die("cannot open > $tmpfile: $!");
while (<$fh>) {
  chomp();
  @_ = split(/\s+/);
  push (@blast,
    [
    $_[0],  # 0 query accession
    $_[1],  # 1 subject accession [= contig id]
    $_[2],  # 2 % identity
    $_[8],  # 3 subject start
    $_[9],  # 4 subject end
            # 5 [added later] feature name
            # 6 [added later] feature id
            # 7 [added later] orientation
    ]
  );
}
close $fh;
#unlink ($tmpfile);

if (-e $mapfile) {
  # Read map file (gene feature only)
  my @map;
  open($fh, $mapfile) or die("cannot open > $mapfile: $!");
  while (<$fh>) {
    if (!/^#/) {
      chomp();
      @_ = split(/[\s\|]+/);
      if ($_[11] eq 'GENE') {
        $_[5] =~ s/\.\d+$//; # Remove version
        push(@map,
          [
          $_[5],  # 0 contig id
          $_[1],  # 1 chromosome
          $_[2],  # 2 start
          $_[3],  # 3 stop
          $_[4],  # 4 orientation
          $_[9],  # 5 feature name
          $_[10], # 6 feature id
          ]
        );
      }
    }
  }
  close $fh;

  # Add map information
  for (my $i = 0; $i < scalar(@blast); $i++) {
    for (my $f = 0; $f < scalar(@map); $f++) {
      if ($blast[$i][1] eq $map[$f][0]) {
        if (($blast[$i][3] >= $map[$f][2]) && ($blast[$i][3] <= $map[$f][3])) {
          $blast[$i][5] = $map[$f][5]; # feature name
          $blast[$i][6] = $map[$f][6]; # feature id
          $blast[$i][7] = $map[$f][4]; # orientation
          $blast[$i][8] = $map[$f][1]; # chromosome etc
          last;
        }
      }
    }
    # Output results as tabbed csv
    print join("\t", @{$blast[$i]}), "\n";
  }
}
else {
  # No gene map data, just output blast results
  for (my $i = 0; $i < scalar(@blast); $i++) {
    print join("\t", @{$blast[$i]}), "\n";
  }
}
exit(0);


sub PriUsage {
  PriVersion();
  print "Usage:\n";
  print "fraves_blast.pl [-help] -query 'filename' [-database 'database-name'] [-evalue integer] \n";
}

sub PriVersion {
  print "fraves_blast.pl ver. $version\n";
}
