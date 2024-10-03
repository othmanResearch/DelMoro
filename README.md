## DelMoro 
---

**DelMoro** is a workflow designed to detect variants on whole Genome- Exome sequencing data. It is built using Nextflow, a workflow tool to run tasks across multiple compute infrastructures. The pipeline is designed for detecting genetic variants, and it may be analyses SNPs for different spicies. DelMoro uses Conda/Mamba which makes installation trivial and results highly reproducible, Docker and Singularity containers are underconstruction.

---
### Workflow

![Pipeline](./pipelineDelMoro.png)

---
1- To Run DelMoro first create using conda Delmoro Environment : 
~~~
conda env create -f DelMoro.yml && conda activate DelMoro
~~~
2- To check Delmoro commands :  
~~~
nextflow main.nf 
~~~
3- Error Handling : If you typed wrongly any params, an Error message will appear.

4- To See Defauls Params : 
~~~
nextflow main.nf --exec ShowParams
~~~
5- To Modify any params e.g. Threads which refers to cpus, type 
~~~
nextflow main.nf --exec Trimm --cpus 10
~~~
6- CAll SNP : the pipeline generates by default vcf files, select SNP for all inputs and a cohorte GVCF  . 
~~~
nextflow main.nf --cpus 8 --exec CallSNP 
~~~
  * In case you wanna only generate vcf for all input add the parameter --generate
~~~
nextflow main.nf --cpus 8 --exec CallSNP --generate onlyVCF
~~~
  * In case you wanna generate a cohorte GVCF 
~~~
nextflow main.nf --cpus 8 --exec CallSNP --generate cohorteGVCF
~~~


