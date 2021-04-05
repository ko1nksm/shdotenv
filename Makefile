PREFIX ?= /usr/local
BINDIR := $(PREFIX)/bin

.PHONY: all build check test package clean install uninstall

all: build package

build:
	./src/build.sh < src/shdotenv > ./shdotenv
	chmod +x ./shdotenv

check:
	shfmt -w -ci -ln posix src/build.sh src/shdotenv
	shellcheck src/build.sh src/shdotenv

test: check
	shellspec +q

package:
	tar czf shdotenv.tar.gz shdotenv

clean:
	rm shdotenv shdotenv.tar.gz

install:
	install -m 755 shdotenv $(BINDIR)/shdotenv

uninstall:
	rm $(BINDIR)/shdotenv
