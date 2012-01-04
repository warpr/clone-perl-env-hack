#!/usr/bin/env perl

use strict;
use warnings;
use CPAN;
use CPAN::Shell;

sub get_files
{
    my $dir = shift;
    my %ret;

    opendir(DIR, $dir) or die $!;

    while (my $file = readdir(DIR))
    {
        next unless $file =~ m/\.tar\.gz$/;

        my $stem = $file;
        $stem =~ s/-[0-9]+(\.[0-9]+)+.tar.gz$//;
        $stem =~ s/-[0-9]+(\.[0-9]+)+.tgz$//;
        $ret{$stem} = $file;
    }

    closedir(DIR);

    return %ret;
}

sub get_deps
{
    my ($pkg, $files) = @_;
    my %ret;

    my @output = `cpanm --showdeps $pkg`;
    for my $module (@output)
    {
        chomp $module;
        $module =~ s/~.*//;

        next if $module eq 'Class::MOP';  # Expands to Moose.
        
        my $distribution = CPAN::Shell->expand("Module", $module);
        next unless $distribution;

        my $stem = $distribution->cpan_file;
        $stem =~ s,.*/,,;
        $stem =~ s/-[0-9]+(\.[0-9]+)+.tar.gz$//;
        $stem =~ s/-[0-9]+(\.[0-9]+)+.tgz$//;

        # work around dependancy loop between ExtUtils::MakeMaker and
        # Data::Dumper;
        next if $stem eq 'ExtUtils-MakeMaker';
        next if $stem eq 'Data-Dumper';

        $ret{$files->{$stem}} = 1 if exists $files->{$stem};
    }

    return \%ret;
}

sub resolve_deps
{
    my %deps = @_;

    my @ret;

    my $remaining = scalar keys %deps;
    while ($remaining > 0)
    {
        my @no_dep_packages;

        # find packages with no dependancies anymore
        for my $key (keys %deps) {
            next unless scalar keys %{ $deps{$key} } == 0;

            push @no_dep_packages, $key;
        }

        for my $key (@no_dep_packages) { delete $deps{$key}; }

        # find newly listed files and remove them as deps
        for my $key (keys %deps) {
            for my $file (@no_dep_packages) {
                delete $deps{$key}{$file};
            }
        }

        # add previously found packages to the list of packages to install.
        push @ret, @no_dep_packages;

        if (scalar keys %deps == $remaining)
        {
            print "Dependancy loop detected :(\n";
            use Data::Dumper;
            local $Data::Dumper::Sortkeys = 1;
            print Dumper (\@ret)."\n";
            print "==================================\n";
            print Dumper (\%deps)."\n";
            exit 0;
        }

        $remaining = scalar keys %deps;
    }

    return @ret;
}

sub main
{
    my $outputfile = shift;

    my %deps;
    my %files = get_files (".");

    for my $filename (sort values %files)
    {
        $deps{$filename} = get_deps ($filename, \%files);
    }

    my @order = resolve_deps (%deps);

    open (my $fh, ">$outputfile");
    print $fh join ("\n", @order)."\n";
    close ($fh);

    print "Saved install order to $outputfile\n";
}

if (scalar @ARGV == 1)
{
    main ($ARGV[0]);
}
else
{
    print "Usage: order_by_deps.pl <outputfile>\n";
}
