
filelist:
	./scripts/filelist.py | sort > meta/filelist.txt

check-dot:
	perl5.30 -c mac/dot

