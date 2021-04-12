PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

.PHONY: build check test dist clean install uninstall

build: test
	cat LICENSE.build > ./shdotenv
	./src/build.sh < src/shdotenv | shfmt -mn -ln posix >> ./shdotenv
	chmod +x ./shdotenv

check:
	shfmt -d -ci -i 2 -ln posix src/build.sh src/shdotenv
	shellcheck src/build.sh src/shdotenv

test: check
	shellspec +q

fix:
	shfmt -w -ci -i 2 -ln posix src/build.sh src/shdotenv

dist: build
	tar czf shdotenv.tar.gz shdotenv

clean:
	rm -f shdotenv shdotenv.tar.gz

install:
	install -m 755 shdotenv $(BINDIR)/shdotenv

uninstall:
	rm $(BINDIR)/shdotenv
