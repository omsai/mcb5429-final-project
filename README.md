Makefiles for running ChIP-seq and RNA-seq pipelines.

Usage
-----

To run the pipelines on the Bioinformatics cluster, you can use the
two provided job submission scripts:

```bash
$ qsub chipseq.sh
$ qsub rnaseq.sh
```

This will execute the makefiles in the chipseq and rnaseq directories,
respectively.


Interactive
-----------

One can manually run various sections of the makefile inside a login
shell by changing to the directories containing the makefiles and
running the makefile rules.

`all` is the first rule appearing in the Makefile, and therefore when
running make with no targets, all the rules are executed.  Use grep To
see a list of all rules:

```bash
$ cd rnaseq
$ grep ^all Makefile
all : qc trim align bedgraph htseq
```

To only run the rnaseq align rule:

```bash
$ qrsh -pe smp 8
$ cd path/to/rnaseq/
$ make threads=8 align
```

Note that one needs to change directories after `qrsh` because `qrsh`
and `qlogin` both seem to ignore the `-cwd` and `-wd` options:

```bash
$ qrsh -wd $(pwd)
error: Unknown option -wd
$ qlogin -cwd
error: Unknown option -wd
```
