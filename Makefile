
download_musicbrainz_deps.sh: download.txt
	echo "#!/bin/bash" > $@
	grep 'tp://' < $< | sed 's/^/wget -c /' > $@
	chmod +x $@

install_musicbrainz_deps.sh: install_order.txt
	echo "#!/bin/bash" > $@
	echo "set +e" >> $@
	sed 's/^/cpanm --notest /' < $< >> $@
	chmod +x $@


