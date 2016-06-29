url = http://zlib.net/zlib-1.2.8.tar.xz
tarball = $(lastword $(subst /, ,$(url)))
p = $(tarball:.tar.xz=)
pn = $(shell echo "$(firstword $(subst -, ,$(p)))" | tr 'A-Z' 'a-z')
prefix = /home/$(USER)/apps/$(pn)
target_final = $(prefix)/bin/$(pn)
target_module = /home/$(USER)/mod/$(pn)
define modulefile
#%Module1.0

conflict $(pn)

set prefix $(prefix)

prepend-path INCLUDE $$prefix/include
prepend-path LD_LIBRARY_PATH $$prefix/lib
prepend-path MANPATH $$prefix/share/man
endef
export modulefile

$(target_module) : | $(target_final)
	echo "$${modulefile}" >> $@

$(target_final) : $(p)/Makefile
	$(MAKE) -C $(<D) -j $$(nproc) && \
	$(MAKE) -C $(<D) install

$(p)/Makefile : $(p)/configure
	cd $(<D) && \
	./configure --prefix=$(prefix)

$(p)/configure : $(tarball)
	tar -xvJpf $<
	touch -r $@ $<

$(tarball) :
	wget '$(url)' -O $@
