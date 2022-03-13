#!/usr/bin/perl
#
use strict;
use warnings;

use YAML::Tiny;
my $yaml = YAML::Tiny->read('re.yaml');
my $runtime = $yaml->[0];     # reference to the first document
print "$runtime\n";
foreach my $key (keys %$runtime) {
  print "key: $key\n";
}
my $requests = $yaml->[0]->{dockerDaemonScheduler}->{defaultDindResources}->{requests};
#print $requests->{cpu},"\n";
#$requests->{cpu} = '1000m';
#print $requests->{cpu},"\n";
$requests->{memory} ="2000mi";  # add value
#print $requests->{memory},"\n";
# Write file
$yaml->write('re.yaml');
