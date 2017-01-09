#!/usr/bin/perl -w
#
# Connect scaffold names to the full featured genbank entries
# This script will work for the Fragaria vesca genome only
#
# Paths
my $genome_path = '/home/ter062/Documents/Forsk/Genome/Fragaria_vesca_genome_2017-01-02/';
my $assembled_path = $genome_path . 'Assembled_chromosomes/';
my $seq_path = $assembled_path . 'seq/';
# files
my $link_file = 'chr_NC_gi';
my $scaffold_names_file = 'scaffold_names';
my $chr_file_prefix = '101020_ref_FraVesHawaii_1.0_chr';

# Read the links file
# contains: Chr, Accession.ver, gi, Assembly and unit, Assembly-unit, accession.version
# We want to keep: "Chr", and "Accession.ver"

my %acc;
my @chrs;
my $inputfile = $assembled_path . $link_file;
open(my $fh, $inputfile) or die "cannot open > $inputfile: $!";
while (<$fh>) {
  if (!/^#/) {
    chomp();
    @_ = split(/\s+/);
    $acc{$_[0]} = $_[1];
    push(@chrs, $_[0]);
  }
}
close $fh;

# Connect the Assembled chromosomes to the scaffolds by reading the scaffold names file
# Contains: Assembly, Genome Center name, RefSeq Accession.version, GenBank Accession.version, NCBI name
# We want to connect Chromosome name to relevant scaffold ("RefSeq Accession.version" is in allcontig.agp)

my %sca;
my @chrsca_list;
$inputfile = $genome_path . $scaffold_names_file;
open($fh, $inputfile) or die "cannot open > $inputfile: $!";
while (<$fh>) {
  if (!/^#/) {
    chomp();
    @_ = split(/\s+/);
    $gav{$_[1]} = $_[2];
    push(@chrsca_list, $_[2]);
  }
}
close $fh;

print "Avoid these scaffolds:\n";
for (@chrs) {
  print $_, ': ', $gav{$_}, "\n";
}
print "Use these instead:\n";
for (@chrs) {
  print $_, ': ', $acc{$_}, "\n";
}
print "Fasta files are in $seq_path:\n";
for (@chrs) {
  my $ffile = $chr_file_prefix . $_ . ".fa.gz";
  if (-e $seq_path . $ffile) {
    print $_, ': ', $ffile, "\n";
    print "gunzipping $ffile...\n";
    system("gunzip $seq_path$ffile");
  }
  else {
    if (-e $seq_path . $chr_file_prefix . $_ . '.fa') {
      print $_, ': ', $ffile, " already unpacked\n";
    }
    else {
      print $_, ': ', $ffile, " missing\n";
    }
  }
}
