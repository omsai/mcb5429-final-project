Analysis of ChIP-seq and RNA-seq data.

Usage
-----

Read Jupyter notebook [report](report.ipynb).
To verify the calculations or explore the data,
run the pipelines and then execute the notebook.

To run the pipelines on the Bioinformatics cluster, you can use the
two provided job submission scripts:

```bash
qsub chipseq.sh
qsub rnaseq.sh
```

These will execute makefiles in the chipseq and rnaseq directories,
respectively.

The wall time for `chipseq` is about 1.5 hours.

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

```
$ make threads=8 align
```

One can verify the commands executed by make using `make -n`.
To trace dependencies, use `make -n -di`

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
echo "alias python=python3" >> ~/.bashrc
echo "alias pip=pip3" >> ~/.bashrc
echo "alias notebook='jupyter notebook --no-browser'" >> ~/.bashrc
source ~/.bashrc
module load python
module initadd python
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

Run the notebook server on the cluster with:

```bash
jupyter notebook --no-browser
```

You should see the notebook serve on a URL like
http://localhost:8080

To view the notebook rom your local machine,
you can setup an SSH tunnel,
and then open your web browser:

```bash
ssh -N -f -L localhost:8080:localhost:8888 <your_username>@bbcsrv3.biotech.uconn.edu
xdg-open http://localhost:8080
```

OSX users would use `open` instead of `xdg-open`

Click on "report.ipynb" in your browser page
and in the new tab that opens click: Cell > Run All.
