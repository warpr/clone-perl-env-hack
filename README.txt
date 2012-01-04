
The scripts in this folder are a collection of ugly hacks used to
clone the musicbrainz perl environment.

If you just wish to install a cloned musicbrainz environment simply
create a new empty local::lib environment, and then run the following
commands:

mkdir dl
cd dl
sh ../download_musicbrainz_deps.sh
sh ../install_musicbrainz_deps.sh

If you want to know more about how these files were created or wish
clone a different environment, continue reading :)

step 1
======

Log in to the machine / user account of which you want to clone the
environment, run "installed.pl" on that machine, e.g. like this:

perl ./installed.pl | tee versions.txt

This will give you list of installed packages with their versions.

step 2
======

Run distributions.pl with versions.txt as input to determine the
locations where each of the packages you need to install can be
downloaded.

distributions.pl requires BackPAN::Index and CPAN to be installed, it
also requires wget and gunzip.  You probably want to run this on your
regular development machine.

perl ./distributions.pl < versions.txt | tee download.txt

grep the output file for lines starting with "NoVersion" and
"NotFound".  No download location could be determined for those, so
you probably have to do those manually.

grep ^No download.txt 


step 3
======

Download all the modules so their dependancies can be determined:

make
mkdir dl
cd dl
sh ../download_musicbrainz_deps.sh


step 4
======

If you want install these modules you cannot just install them
one-by-one, many will require dependancies and these will normally be
resolved against CPAN by installers such as "cpan" or "cpanm" (which
would download a more recent version than the one you're trying to
install).

I have attempted to work around this issue by writing a script to
determine the order in which packages should be installed.  Run it in
the "dl" directory created in the previous step:

perl ../order_by_deps.pl ../install_order.txt
cd ..
make

step 5
======

Now install all this stuff into a fresh local::lib.

First set up a fresh local::lib in ~/perl5:

cd
mv perl5 perl5.old
cd usr
wget http://search.cpan.org/CPAN/authors/id/A/AP/APEIRON/local-lib-1.008004.tar.gz
dtrx local-lib-1.008004.tar.gz
cd local-lib-1.008004
perl Makefile.PL --bootstrap
make test && make install

We want to install stuff using "cpanm", so we will have to install
that first:

cpan install App::cpanminus

Now navigate back to the directory where you've downloaded everything
and run:

../install_musicbrainz_deps.sh

(This script will install everything using "cpanm --notest".  In
general it is safer to do this without --notest, but usually the end
result is the same -- you know some tests fail, but are in no position
to fix them, so you force install that particular package with
--notest anyway).

