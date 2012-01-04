
all: download_musicbrainz_deps.sh install_musicbrainz_deps.sh

download_musicbrainz_deps.sh: download.txt
	echo "#!/bin/bash" > $@
	grep 'tp://' < $< | sed 's/^/wget -c /' > $@
	chmod +x $@

install_musicbrainz_deps.sh: install_order.txt
	echo "#!/bin/bash" > $@
	echo "set +e" >> $@
	echo "cpanm --notest Class-MOP-1.12.tar.gz" >> $@
	echo "cpanm --notest Moose-1.24.tar.gz" >> $@
	sed 's/^/cpanm --notest /' < $< >> $@
	chmod +x $@


