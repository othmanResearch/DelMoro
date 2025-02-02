## DelMoro 
---

**DelMoro** is a workflow designed to detect variants in whole Genome- Exome sequencing data. It is built using Nextflow, a workflow tool to run tasks across multiple compute infrastructures. The pipeline is designed for detecting genetic variants, and it may analyze SNPs for different species. DelMoro uses Conda, Mamba, and Docker which makes installation trivial and results highly reproducible.

---
### Workflow

![Pipeline](./pipelineDelMoro.png)

---
1. **To Run DelMoro**, first create the DelMoro environment using conda: 
~~~bash
conda env create -f DelMoro.yml && conda activate DelMoro
~~~
2. **To check DelMoro commands**:  
~~~bash
nextflow main.nf 
~~~
- To see the help manual:  
~~~bash
nextflow main.nf --exec help
~~~

3. **Error Handling**: If you type any parameters incorrectly, an error message will appear.

4. **To See Default Params**: 
~~~bash
nextflow main.nf --exec params
~~~

DelMoro offers users the possibility of generating automatically required CSV files for its processes. As an initial step, the USER prepares an input CSV to write downstream CSVs.
~~~bash
nextflow main.nf --generate CSV --basedon CSVs/1_samplesheetForRawQC.csv 
~~~
The **1_samplesheetForRawQC.csv** must be as below (template):
~~~csv
patient_id,R1,R2
AO22K1,./Data/DEL_1.fastq.gz,./Data/DEL_2.fastq.gz
TOK2W0,./Data/MORO_1.fastq.gz,./Data/MORO_2.fastq.gz
3OL51K,./Data/TUN_1.fastq.gz,./Data/TUN_2.fastq.gz
~~~
Outputs of the generated CSVs are as follows:

- *2_SamplesheetForTrimming.csv*:
~~~csv
patient_id,R1,R2,MINLEN,LEADING,TRAILING,SLIDINGWINDOW
AO22K1,./Data/DEL_1.fastq.gz,./Data/DEL_2.fastq.gz,36,30,30,'4:20'
TOK2W0,./Data/MORO_1.fastq.gz,./Data/MORO_2.fastq.gz,36,30,30,'4:20'
3OL51K,./Data/TUN_1.fastq.gz,./Data/TUN_2.fastq.gz,36,30,30,'4:20'
~~~

- *3_samplesheetForAssembly.csv*:
~~~csv
patient_id,R1,R2
AO22K1,./outdir/TrimmedREADS/DEL_1.fastq,./outdir/TrimmedREADS/DEL_2.fastq
TOK2W0,./outdir/TrimmedREADS/MORO_1.fastq,./outdir/TrimmedREADS/MORO_2.fastq
3OL51K,./outdir/TrimmedREADS/TUN_1.fastq,./outdir/TrimmedREADS/TUN_2.fastq
~~~
- *4_samplesheetForBamFiles.csv*:
~~~csv
patient_id,BamFile
AO22K1,./outdir/Mapping/AO22K1_sor@RG@MD.bam
TOK2W0,./outdir/Mapping/TOK2W0_sor@RG@MD.bam
3OL51K,./outdir/Mapping/3OL51K_sor@RG@MD.bam
~~~
- *5_samplesheetReclibFiles.csv*:
~~~csv
patient_id,BamFile
AO22K1,./outdir/Mapping/AO22K1_sor@RG@MD.bam.recal.bam
TOK2W0,./outdir/Mapping/TOK2W0_sor@RG@MD.bam.recal.bam
3OL51K,./outdir/Mapping/3OL51K_sor@RG@MD.bam.recal.bam
~~~

5. **To Modify any params** (e.g., Threads which refers to CPUs), type:
~~~bash
nextflow main.nf --exec trim  --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --cpus 10
~~~

6. **Call SNPs**: The pipeline generates VCF files by default, select SNP for all inputs and a cohort GVCF. 
~~~bash
nextflow main.nf --cpus 8 --exec callsnp --tovarcall <path-to-csv5> --reference <path-to-reference>
~~~
  * In case you want to only generate VCF for all input, add the parameter `--generate`:
~~~bash
nextflow main.nf --cpus 8 --exec callsnp --tovarcall <path-to-csv5> --reference <path-to-reference> --generate onlyVCF
~~~
  * In case you want to generate a cohort GVCF:
~~~bash
nextflow main.nf --cpus 8 --exec callsnp --tovarcall <path-to-csv5> --reference <path-to-reference> --generate cohorteGVCF
~~~
---
The user has the ability to run each step by specifying parameters (inputs and outputs) or to prepare a **params.json** file as below. To use nextflow.config with its profiles, it is recommended to use **params.json** to specify the desired profile.
~~~bash
 nextflow main.nf -params-file params.json -profile conda,mamba,docker --exec refidx 
~~~ 
- For reference indexing, either you run the refidx on a local reference or use the `--igenome` parameter (check conf/):
~~~bash
nextflow main.nf --exec refidx --igenome GATK.GRCh37
~~~
- For base quality score recalibration, either you use a local VCF or `--ivcf1`, `--ivcf2` parameters (check conf/):
~~~bash
nextflow main.nf --cpus 8 --exec bqsr --reference Reference_Genome/reference.fa --bam CSVs/4_samplesheetForBamFiles.csv --ivcf1 GRCh38.omni --ivcf2 GRCh38.mills1000
~~~

- **params.json**:
~~~json
{	
	"cpus"		: 8,
	"outdir"	: "outdirbasedonjson",
	
	"basedon"	: "./CSVs/1_samplesheetForRawQC.csv",  		 
	"reference"	: "./Reference_Genome/reference.fa",		 

 	"rawreads"	: "./CSVs/1_samplesheetForRawQC.csv", 		 
	"tobetrimmed"	: "./CSVs/2_SamplesheetForTrimming.csv",		 
	"tobealigned"	: "./CSVs/3_samplesheetForAssembly.csv",		 
	"bam"		: "./CSVs/4_samplesheetForBamFiles.csv",
	"tovarcall"	: "./CSVs/5_samplesheetReclibFiles.csv",	  			 		

	"_comment"	: "for base recalibration let either knownSite1 & knownSite2 or ivcf1 & ivcf2",
	
	"knownSite1"	: "./knownsites/1000g_gold_standard.indels.filtered.vcf", 	 
	"knownSite2"	: "./knownsites/GCF.38.filtered.renamed.vcf",	
	
	"ivcf1"		: "GRCh38.mills1000", 	 
	"ivcf2"		: "GRCh38.omni"		  
}
~~~
