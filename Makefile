# Makefile for obarun-build

VERSION = $$(git describe --tags| sed 's/-.*//g;s/^v//;')
PKGNAME = obarun-build

BINDIR = /usr/bin

FILES = $$(find build/ -type f)
SCRIPTS = 	obarun-build.in \
			build.sh
EXTRA = $$(find templates/ -type f)
		
install:
	
	for i in $(SCRIPTS) $(FILES) $(EXTRA); do \
		sed -i 's,@BINDIR@,$(BINDIR),' $$i; \
	done
	
	install -Dm755 obarun-build.in $(DESTDIR)/$(BINDIR)/obarun-build
	install -Dm755 build.sh $(DESTDIR)/usr/lib/obarun/build.sh
	
	for i in $(FILES); do \
		install -Dm755 $$i $(DESTDIR)/usr/lib/obarun/$$i; \
	done
	
	install -Dm644 build.conf $(DESTDIR)/etc/obarun/build.conf
	
	for i in $(EXTRA); do \
		if [[ $$i == create ]]; then \
				install -Dm755 $$i $(DESTDIR)/usr/share/obarun/obarun-build/$$i; \
			else \
				install -Dm644 $$i $(DESTDIR)/usr/share/obarun/obarun-build/$$i; \
			fi \
	done
	
	install -Dm644 PKGBUILD $(DESTDIR)/var/lib/obarun/obarun-build/update_package/PKGBUILD
	
	install -Dm644 LICENSE $(DESTDIR)/usr/share/licenses/$(PKGNAME)/LICENSE

version:
	@echo $(VERSION)
	
.PHONY: install version
