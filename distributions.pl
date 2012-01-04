#!/usr/bin/env perl

use strict;
use warnings;

use BackPAN::Index;
use CPAN;
use CPAN::Shell;
use LWP::UserAgent;

my $cpan_prefix = "ftp://download.xs4all.nl/pub/mirror/CPAN";
my $backpan_prefix = "http://backpan.perl.org";
my $backpan_index = BackPAN::Index->new ({ update => 1 });

sub cpanid
{
    my ($module, $version) = @_;

    my $distribution = CPAN::Shell->expand("Module", $module);

    return unless $distribution;

    my $stem = $distribution->cpan_file;
    $stem =~ s,.*/,,;
    $stem =~ s/-[0-9]+(\.[0-9]+)+.tar.gz$//;
    $stem =~ s/-[0-9]+(\.[0-9]+)+.tgz$//;

    open (FIND, 'find-ls');
    while (<FIND>) {
        my @fields = split m/\s+/;
        my $filename = $fields[8];

        next unless $filename;
        next unless $filename =~ m/\.tar.gz$/ || $filename =~ m/\.tgz$/;
        next unless $filename =~ m/^authors/;
        next unless $filename =~ m/$stem/;
        next unless $filename =~ m/$version/;

        close (FIND); 
        return $filename;
    }
    close (FIND); 

    return;
}

sub backpan_index
{
    my ($module, $version) = @_;

    my $releases = $backpan_index->releases($module);
    return undef unless $releases;

    my $release = $releases->single({ version => $version });
    return undef unless $release;

    return $release->path;
}

sub backpan_recent_author
{
    my ($module, $version) = @_;

    my $distribution = CPAN::Shell->expand("Module", $module);

    return unless $distribution;

    my $location = "authors/id/".$distribution->cpan_file;
    $location =~ s/-[0-9]+(\.[0-9]+)+.tar.gz$/-$version.tar.gz/;

    my $ua = LWP::UserAgent->new;
    my $response = $ua->head ("$backpan_prefix/$location");

    return $location if $response->code == 200;
}

sub get_module_index
{
    `wget $cpan_prefix/indices/find-ls.gz`;
    `gunzip find-ls.gz`;
}

get_module_index unless -f "find-ls";

while (<>)
{
    chomp;
    my ($pkg, $version) = split;

    my $id;

    if (!$version)
    {
        print "NoVersion: $pkg\n";
    }
    elsif ($pkg eq "Class::MOP")
    {
        my $id = "authors/id/F/FL/FLORA/Class-MOP-1.12.tar.gz";
        print "$cpan_prefix/$id\n";
    }
    elsif ($id = cpanid ($pkg, $version))
    {
        print "$cpan_prefix/$id\n";
    }
    elsif ($id = backpan_index ($pkg, $version))
    {
        print "$backpan_prefix/$id\n";
    }
    elsif ($id = backpan_recent_author ($pkg, $version))
    {
        print "$backpan_prefix/$id\n";
    }
    else
    {
        print "NotFound: $pkg $version\n";
    }
}
