#
# setup/Makefile
#

ident       = setup
version     = 3.4.1
include $(HOME)/.makeparams

default: update

.PHONY: default doc text dist clean

clean:
	rm -rf NEWS.ja NEWS.en Usage_* doc.*

publish: update
	cp setup.rb $(datadir)

update:
	update-version --version=$(version) setup.rb

doc:
	rm -rf doc.ja doc.en
	mkdir doc.ja doc.en
	mldoc-split --lang=ja NEWS.m | crd2html > doc.ja/news.html
	mldoc-split --lang=en NEWS.m | crd2html > doc.en/news.html
	compile-documents --lang=ja --template=$(tmpldir)/manual.ja doc doc.ja
	compile-documents --lang=en --template=$(tmpldir)/manual.en doc doc.en

text: Usage_ja.txt Usage_en.txt NEWS.ja NEWS.en

Usage_ja.txt: doc/usage.rd.m
	mldoc-split --lang=ja doc/usage.rd.m | crd2plain > $@
Usage_en.txt: doc/usage.rd.m
	mldoc-split --lang=en doc/usage.rd.m | crd2plain > $@

NEWS.ja: NEWS.m
	mldoc-split --lang=ja NEWS.m > $@
NEWS.en: NEWS.m
	mldoc-split --lang=en NEWS.m > $@

dist:
	rm -rf tmp; mkdir tmp
	cd tmp; cvs -Q export -r`echo V$(version) | tr . -` -d setup-$(version) setup
	cd tmp/setup-$(version); make doc text
	cd tmp/setup-$(version); rm -rf web doc *.m
	cd tmp; tar czf $(siteardir)/setup-$(version).tar.gz setup-$(version)
	rm -rf tmp

site:
	erb web/setup.ja.rhtml | wrap-html --template=$(tmpldir)/basic.ja | nkf -j > $(projdir_ja)/index.html
	erb web/setup.en.rhtml | wrap-html --template=$(tmpldir)/basic.en > $(projdir_en)/index.html
	mldoc-split --lang=ja NEWS.m | crd2html > $(projdir_ja)/doc/news.html
	mldoc-split --lang=en NEWS.m | crd2html > $(projdir_en)/doc/news.html
	compile-documents --lang=ja --template=$(tmpldir)/basic.ja doc $(projdir_ja)/doc
	compile-documents --lang=en --template=$(tmpldir)/basic.en doc $(projdir_en)/doc
