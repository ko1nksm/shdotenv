PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

.PHONY: build check test dist clean install uninstall

build:
	cat ./src/header > ./shdotenv
	./src/build.sh < src/shdotenv >> ./shdotenv
	chmod +x ./shdotenv

all: check test build

check:
	shfmt -d -ci -i 2 -ln posix src/build.sh src/shdotenv
	shellcheck src/build.sh src/shdotenv

test:
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
