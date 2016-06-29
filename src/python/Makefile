url = https://www.python.org/ftp/python/3.5.2/Python-3.5.2.tar.xz
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

prepend-path PATH $$prefix/bin
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
	cd $(@D) && ln -s python{3,}
	cd $(@D) && ln -s pip{3,}

$(p)/Makefile : $(p)/configure
	cd $(<D) && \
	LDFLAGS="-I/home/$(USER)/apps/zlib/include -L/home/$(USER)/apps/zlib/lib" \
	./configure --prefix=$(prefix) \
	--with-ensurepip=install \
	--with-zlib-dir='/home/$(USER)/apps/zlib/lib'

$(p)/configure : $(tarball)
	tar -xvJpf $<
	touch -r $@ $<

$(tarball) :
	wget '$(url)' -O $@
