all: check-perl filelist

filelist:
	./meta/filelist.py | sort > meta/filelist.txt

check-perl:
	perl5.30 -c common.pm
	perl5.30 -c mac/rogu

