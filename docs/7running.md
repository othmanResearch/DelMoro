# Running the Pipeline

This guide allows you to interactively select the pipeline steps you want to run and view the corresponding command.

---


## Help Menu 
```
Program : DelMoro (Bioinformatics Tool Used In Clinical Genomics)
Version : v1.00 
Github  : https://github.com/othmanResearch/DelMoro
Documentation : - 


Usage   : nextflow run main.nf <modality> [--exec <module>] <params>

Modality: - --fullmode  : Executing   full   mode from fastq until vaiant calling.
	      - --stepmode  : Executing   different   modules   in   standalone  mode.



Executing fullmode :  
nextflow run main.nf  
    --fullmode
    --input  
    --reference   | [--igenome ]   
    [--aligner bwamem2]  
    [--mode onlyVCF|cohortGVCF]  
    [--bqsr]  
    [--knownsite1 ,--knownsite2 |--ivcf1 ,--ivcf2 ]


~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Executing stepmode :  
nextflow run main.nf  
    --stepmode
    --exec <module>

Module  : - rawqc 	    : Check quality of raw reads. 
	      - trim 	    : Remove low-quality bp and adapters & checks its quality.
	      - refidx 	    : Index the reference genome for alignment.
	      - align 	    : Align reads to the reference genome.
	      - bqsr 	    : Base Quality Score recalibration.
	      - callsnp 	: Detect SNPs from aligned reads.
	      - annotate 	: annotate vfc file.
	      - reporting 	: Auto Generate PDF of  vcf reports.
	      - help 	
	      - version  
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Requirements :
  -- Quality Control
     rawqc 	   Check quality of raw reads. 
                require : --rawreads <path-to-csv>
                output  : .html reads 
                   	    : .html multiqc 

  -- Trimming
     trim          Remove low-quality bp and adapters & checks its quality.
     		    require : --tobetrimmed <path-to-csv>
     		   	        : --trimmomatic, --fastp, --bbduk 
     		            : --adapters <path-to-adapter-file> [ optional ]
     		    output  : .fastq trimmed 
                   	    : .html trimmed reads 
                   	    : .html multiqc  

  -- Indexing
     refidx 	   Index reference genome for alignment.
     		    require : --reference <path-to-ref>
     		   	        : --igenome   <value-from-IGENOMES> [ optional ]
     		    output  : .dict 
                        : .fai  
                        : .{.0123,amb,ann,bwt.2bit.64,pac} 
   
  -- Mapping	   
     align         Align reads to reference genome.
  	            require : --reference   <path-to-ref>
  	            	    : --Tobealigned <path-to-trimmed-csv>
  		                : --metrics  [ optional ]
  		                : --mindepth [ optional ] 
  		                : --saveImg  [ optional ] 
  	            output  : .bam
  	           	        : .bai
  	           	        : .flagstat
  	           	        : .coverage.bed
  	                    : .bw
  
    -- BQSR  
     bqsr	   Base quality score recalibration.
  		        require : --knownsite1, 2 <path-to-vcf-file> , 2 files 
  		   	            : --ivcf1, 2      <value>  [ optional ]
  		                : --bam	     <path-to-bam-csv)
  		                : --metrics  [ optional ]
  		                : --mindepth [ optional ] 
  		                : --saveImg  [ optional ] 
		        output  : .idx of knwons sites <vcf> 
		   	            : .table
		   	            : .bam
		   	            : .bam
		   	   	           	   
  -- Variant Calling	  
     callsnp       Detect SNPs from aligned reads.
  	            require : --reference   <path-to-ref>
  		   	            : --tovarcall   <path-to-bam-csv)
  		        output  : .vcf
  		   	            : .table
  -- Annotation	  
     annotate       Print out Annotation manual
     
     vepcache       Download vep cache
  	            require : --species   <value>
  	           	        : --cachetype <value> [ optional ]
  	           	        : --assembly  <value> [ optional ]
  	           	        : --cacheversion  <value> [ optional ] 
  	            output  : ./vep_cache directory 
  	            
     vepannotate    Vep annotation
  	            require : --species    <value>
  	            	    : --reference  <path-to-ref>
  	            	    : --toannotate <path-to-csv> 
  	           	        : --assembly   <value>
  	           	        : --cachetype  <value> [ optional ]
  	            output  : vcf.gz
  	            	    : .vcf.gz.tbi
  	            	    : .html
   -- Reporting
      reporting       Auto Generate PDF of vcf reports
  	            require : --metaPatients <path-to-csv>
			            : --metaYaml 	 <path-to-yaml>
  	            output  : .png
  	            	    : .pdf
 	   		
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  To see Defauls params paths:  
   > nextflow main.nf --params


```

<!-- 🔹 Step 1: Initialize the pipeline -->
## full mode
The **DelMoro full mode** follows a standard workflow, requiring an `--input` CSV file formatted like the example in the [Config Section](6config.md#rawqc-csv-template) and a `--reference` path.  

In this mode, the pipeline performs **reference indexing**, **mapping**, and **variant calling**, applying the same sub-options for each step:  
- **Reference**: `igenome/reference`  
- **Aligner**: `bwa` or `bwamem2`  
- **Mode**: `onlyVCF` or `cohortGVCF`  

You can optionally enable **Base Quality Score Recalibration (BQSR)** by adding the `--bqsr` parameter, which requires either:  
- Local known sites: `--knownsite1`, `--knownsite2`  
- retrieval from AWS: `--ivcf1`, `--ivcf2`  

<div id="fullmode-cmd" class="full-command">
<pre><code>
nextflow run main.nf \
    --fullmode \
    --input <input_csv> \
    --reference <reference_path>  | [--igenome <str>]  \
    [--aligner bwamem2] \
    [--mode onlyVCF|cohortGVCF] \
    [--bqsr] \
    [--knownsite1 <path>,--knownsite2 <path>|--ivcf1 <str>,--ivcf2 <str>]
</code></pre>
</div>

## Step mode
### Step 1: Initialize the Pipeline

<div align="justify"> 
This step sets up the required input data.  
It prepares all necessary CSV files used in downstream analysis.  
These files are automatically generated based on an initial CSV file provided by the user.
<br><br>
</div>

<!-- 🔸 Step 1: CSV file template toggle -->
??? note " 💡 **Template of the CSVs/1_samplesheetForRawQC.csv**"
    Header : patient_id,R1,R2
    ```
    patient_id,R1,R2
    41,./Data/father_1.fastq.gz,./Data/father_2.fastq.gz
    22,./Data/mother_1.fastq.gz,./Data/mother_2.fastq.gz
    33,./Data/son_1.fastq.gz,./Data/son_2.fastq.gz
    ```


<!-- 🔸 Step 1: Initialization command toggle -->

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-init', this)">
  <strong>Run Initialization</strong>
</label>

<div id="cmd-init" class="step-command">
<pre><code>nextflow run main.nf --stepmode --generate CSV --basedon CSVs/1_samplesheetForRawQC.csv</code></pre>
</div>

---

<!-- 🔹 Step 2: Quality Control -->

### Step 2: Quality Control

<div align="justify">  
Perform quality checks on raw FASTQ files using tools like FastQC,  
and summarize results with MultiQC.
<br><br>
</div>

<!-- 🔸 Step 2: QC command toggle -->

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-qc', this)">
  <strong>Run Quality Control</strong>
</label>

<div id="cmd-qc" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec rawqc --rawreads CSVs/1_samplesheetForRawQC.csv</code></pre>
</div>

<!-- 🔹 Step 3: Read Trimming -->

### Step 3: Read Trimming

<div align="justify">  
This step removes adapters and low-quality bases from reads  
using your choice of trimming tools such as Trimmomatic, fastp, or BBDuk.  
Input is provided via a generated CSV file.  
You may also optionally provide a custom adapter file.
<br><br>
</div>

<!-- Note about adapter option -->

???+ note " 💡About --adapters parameter"
    The `--adapters` parameter is **optional**.  
    If provided, it should point to a FASTA file containing adapter sequences for trimming.

<!-- 🔸 Trimmomatic -->

#### Trimmomatic

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-trim-trimmomatic', this)">
  <strong>Run Trimming with Trimmomatic</strong>
</label>

<div id="cmd-trim-trimmomatic" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec trim --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --trimmomatic --adapters polyA_polyG.fa</code></pre>
</div>

<!-- 🔸 fastp -->

#### fastp

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-trim-fastp', this)">
  <strong>Run Trimming with fastp</strong>
</label>

<div id="cmd-trim-fastp" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec trim --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --fastp --adapters polyA_polyG.fa </code></pre>
</div>
 
<!-- 🔸 BBDuk -->

#### BBDuk

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-trim-bbduk', this)">
  <strong>Run Trimming with BBDuk</strong>
</label>

<div id="cmd-trim-bbduk" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec trim --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --bbduk --adapters polyA_polyG.fa</code></pre>
</div>
 

<!-- 🔹 Step 4: Reference Indexing -->

### Step 4: Index the Reference Genome

<div align="justify">  
This step prepares the reference genome by generating the necessary index files.  
You can either use your own FASTA file placed in the `Reference_Genome/` directory,  
or use the `--igenome` parameter to automatically download and index a standard reference genome.
</div>

---

#### Local Reference

???+ note " 💡**Option 1**: Local FASTA"
    Use your own reference FASTA file.  
    Place it inside the `Reference_Genome/` directory and use the following command:

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-refidx-local', this)">
  <strong>Run Reference Indexing (with local FASTA)</strong>
</label>

<div id="cmd-refidx-local" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec refidx --reference Reference_Genome/reference.fa</code></pre>
</div>

---

#### iGenomes Reference

???+ note " 💡**Option 2**: Auto-download with iGenomes"
    Use the `--igenome` parameter to fetch and index a reference genome.  
    Example: `--igenome Ens.GRCh37`

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-refidx-igenome', this)">
  <strong>Run Reference Indexing (auto-download with iGenomes)</strong>
</label>

<div id="cmd-refidx-igenome" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec refidx --igenome Ens.GRCh37</code></pre>
</div>

---

#### Aligner Option

???+ note " 💡 **Aligner Customization**"
    The default aligner used is `bwa` for both the **indexing** and **alignment** steps.  
    To switch to `bwamem2`, simply add the `--aligner bwamem2` flag to the command.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-refidx-aligner', this)">
  <strong>Run Reference Indexing with BWA-MEM2</strong>
</label>

<div id="cmd-refidx-aligner" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec refidx --reference Reference_Genome/reference.fa --aligner bwamem2</code></pre>
</div>

---

### Step 5: Alignment
<div align="justify">  
This step aligns your sequencing reads to the reference genome using the specified aligner (default is `bwa`).  
You can choose to use `bwamem2` by specifying the `--aligner bwamem2` flag.
<br><br>
</div> 
 
<label>
  <input type="checkbox" onchange="toggleCommand('cmd-align', this)">
  <strong>Run Alignment</strong>
</label>

<div id="cmd-align" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec align --reference Reference_Genome/reference.fa --tobealigned CSVs/3_samplesheetForAssembly.csv --aligner bwamem2 </code></pre>
</div>

---

### Step 6: Base Quality Score Recalibration

<div align="justify">
This step applies GATK's Best Practices for Base Quality Score Recalibration (BQSR).  
It adjusts the quality scores of sequencing reads using known variant sites to improve variant calling accuracy.  
You can either use your own VCF files or download reference sets automatically using the `--ivcf` parameters.
</div>

---

#### Local Known Sites (VCF files)

???+ note " 💡 **Option 1**:"
    Use locally downloaded VCF files for known sites.  
    You must specify their paths using `--knownsite1` and `--knownsite2`.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-bqsr-local', this)">
  <strong>Run BQSR (with local known sites)</strong>
</label>

<div id="cmd-bqsr-local" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec bqsr \
  --reference Reference_Genome/reference.fa \
  --bam CSVs/4_samplesheetForBamFiles.csv \
  --knownsite1 knownsites/1000g_gold_standard.indels.filtered.vcf \
  --knownsite2 knownsites/GCF.38.filtered.renamed.vcf</code></pre>
</div>

---

#### Auto-Download Known Sites

???+ note " 💡 **Option 2**:"
    Use `--ivcf1` and `--ivcf2` to automatically download public known sites for BQSR.  
    Examples: `GRCh38.mills1000`, `GRCh38.dbsnp`.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-bqsr-auto', this)">
  <strong>Run BQSR (auto-download known sites)</strong>
</label>

<div id="cmd-bqsr-auto" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec bqsr \
    --reference Reference_Genome/reference.fa \
    --bam CSVs/4_samplesheetForBamFiles.csv \
    --ivcf1 GRCh38.mills1000 \
    --ivcf2 GRCh38.omni
</code></pre>
</div>

---

### Step 7: Variant Calling

<div align="justify">
This step performs variant calling using the final recalibrated BAM files.  
By default, it generates a VCF file for each patient, extracts a variant table, filters SNPs, and automatically creates per-sample GVCF files.  
You can modify the output behavior using the `--generate` flag:
</div>

---

#### Default Mode

???+ note " 💡 **Default Behavior**:"
    - Generates VCF files for each patient  
    - Extracts tabular variant summary  
    - Filters SNPs  
    - Generates phased BAM files for each sample  
    - Automatically produces individual GVCF files
 
<label>
  <input type="checkbox" onchange="toggleCommand('cmd-call-default', this)">
  <strong>Run Variant Calling (default)</strong>
</label>

<div id="cmd-call-default" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec callsnp \
  --reference Reference_Genome/reference.fa \
  --tovarcall CSVs/5_samplesheetReclibFiles.csv</code></pre>
</div>

---

#### Generate Only VCF & SNP Table

???+ note " 💡 **Option:** `--generate onlyVCF`"
    - Skips GVCF creation  
    - Outputs only the main VCF file, variant table, and SNP table

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-call-onlyvcf', this)">
  <strong>Run Variant Calling (only VCF + SNP)</strong>
</label>

<div id="cmd-call-onlyvcf" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec callsnp \
  --reference Reference_Genome/reference.fa \
  --tovarcall CSVs/5_samplesheetReclibFiles.csv \
  --generate onlyVCF</code></pre>
</div>

---

#### Generate Cohort GVCF

???+ note " 💡 **Option:** `--generate CohorteGVCF`"
    - Produces a single joint cohort `.g.vcf` file  
    - Useful for population-level variant analysis or joint genotyping

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-call-cohortgvcf', this)">
  <strong>Run Variant Calling (Cohort GVCF)</strong>
</label>

<div id="cmd-call-cohortgvcf" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec callsnp \
  --reference Reference_Genome/reference.fa \
  --tovarcall CSVs/5_samplesheetReclibFiles.csv \
  --generate cohorteGVCF</code></pre>
</div>

### Step 8: Variant Annotation

This step adds functional information to your variants using **Ensembl VEP (Variant Effect Predictor)**.

---

#### VEP Cache Downloading

???+ note "💡 VEP Cache Notes"
    - VEP requires a local cache for annotation.
    - The **minimum required** argument is `--species`.
    - Optional arguments:
        - `--cachetype` (e.g., `refseq` or `merged`)
        - `--assembly` (e.g., `GRCh37` or `GRCh38`)
        - `--cacheversion` (e.g., `113 or 114`) 
    - The output cache will be saved in the `./.vepcachedir/` directory.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-min-vep-cache', this)">
  <strong>Download VEP Cache</strong> with minimum required argument
</label>

<div id="cmd-min-vep-cache" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec vepcache --species homo_sapiens</code></pre>
</div>


<label>
  <input type="checkbox" onchange="toggleCommand('cmd-full-vep-cache', this)">
  <strong>Download VEP Cache</strong> with full arguments
</label>

<div id="cmd-full-vep-cache" class="step-command">
<pre><code>nextflow run main.nf --stepmode --exec vepcache --species homo_sapiens --assembly GRCh37 --cachetype refseq --cacheversion 114 -profile docker</code></pre>
</div>

---

#### VEP Annotation

???+ note "💡 About VEP Annotation"
    - This step uses **VEP (Variant Effect Predictor)** to annotate VCF files with predicted variant effects.  
    - You must specify :
        - `--toannotate` (vcf csv file)
        - `--species` (e.g., `homo_sapiens`)
        - `--assembly` (e.g., `GRCh37` or `GRCh38`)

    - And optionally :
        - `--cachetype` (e.g., `refseq` or `merged` ...)
        - `--cachedir` path to the downloaded cache directory.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-vep-annotate', this)">
  <strong>Run VEP Annotation</strong>
</label>

<div id="cmd-vep-annotate" class="step-command">
<pre><code>nextflow main.nf --stepmode --exec vepannotate \
  --toannotate CSVs/6_samplesheetvcfFiles.csv \
  --reference Reference_Genome/reference.fa \
  --species homo_sapiens \
  --assembly GRCh37 \
  --cachedir .vepcachedir/</code></pre>
</div>

### Reporting 
- This step creates detailed reports from the vep annotated  VCF files. 

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-repoting', this)">
  <strong>Run Reporting</strong>
</label>

<div id="cmd-repoting" class="step-command">
<pre><code>nextflow main.nf --stepmode --exec reporting \
  --metaPatients CSVs/7_metaPatients.csv \ 
  --metaYaml CSVs/7_metaPatients.yml 
</code></pre>
</div>



### Filtering

- This step applies variant filtering using the specified CSV file.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-filtering', this)">
  <strong>Run Filtering</strong>
</label>

<div id="cmd-filtering" class="step-command">
<pre><code>nextflow main.nf --stepmode --exec filter \
  --tofilter CSVs/tofilter.csv
</code></pre>
</div>
