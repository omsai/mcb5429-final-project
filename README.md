Makefiles and report for analyzing ChIP-seq and RNA-seq data.

Usage
-----

To run the pipelines on the Bioinformatics cluster, you can use the
two provided job submission scripts:

```bash
qsub chipseq.sh
```

```bash
qsub rnaseq.sh
```

This will execute the makefiles in the chipseq and rnaseq directories,
respectively.

WARNING: Due to the 50 GB disk space quota on the cluster,
you should only ever run one job submission script at a time.
The intermediate files use tens of GB of disk space during execution.
Upon completion (or error), `make` automatically deletes intermediate files to just a few GB,
but if both scripts are run at the same time, the disk space might get filled.

Pipeline Development
--------------------

One can manually run various sections of the makefile inside a login
shell by changing to the directories containing the makefiles and
running the makefile rules.

`all` is the first rule appearing in the Makefile, and therefore when
running make with no targets, all the rules are executed.  Use grep To
see a list of all rules:

```bash
cd rnaseq
grep ^all Makefile
```

```
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

Report Development
------------------

To generate the report, you need to install Jupyter using Python `pip`.
Python 2.7.3 on the cluster freezes the notebook kernels,
due to trouble with sqlite3 calls similar to [issue 6165](https://github.com/ipython/ipython/issues/6165).
Therefore one needs to compile Python 3 from source:

```bash
make -C src/zlib
make -C src/python
echo "MODULEPATH=${HOME}/mod:${MODULEPATH}"
module initadd python
echo "alias python=python3" >> ~/.bashrc
echo "alias pip=pip3" >> ~/.bashrc
echo "alias notebook='jupyter notebook --no-browser'" >> ~/.bashrc
source ~/.bashrc
```

Then install Jupyter with 

```bash
pip install jupyter`
```

Install the [R kernel](https://irkernel.github.io/installation/#source-panel)
for Jupyter:

```bash
module load R/3.2.2
module initadd R/3.2.2
R
```

```R
install.packages(c('rzmq','repr','IRkernel','IRdisplay'),
                 repos = c('http://irkernel.github.io/',
                           getOption('repos')), type = 'source')
IRkernel::installspec()
```

To view the notebook on the cluster from your local machine,
you can setup an SSH tunnel:

```bash
jupyter notebook --no-browser
ssh -N -f -L localhost:8080:localhost:8888 <your_username>@bbcsrv3.biotech.uconn.edu
```

Then on your client machine, open a web browser to that port:

```bash
xdg-open http://localhost:8080
```
