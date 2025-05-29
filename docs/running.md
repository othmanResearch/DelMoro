# Running the Pipeline

This guide allows you to interactively select the pipeline steps you want to run and view the corresponding command.

---

<!-- 🔹 Step 1: Initialize the pipeline -->

## Step 1: Initialize the Pipeline

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
<pre><code>nextflow run main.nf --generate CSV --basedon CSVs/1_samplesheetForRawQC.csv</code></pre>
</div>

---

<!-- 🔹 Step 2: Quality Control -->

## Step 2: Quality Control

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
<pre><code>nextflow run main.nf --exec rawqc --rawreads CSVs/1_samplesheetForRawQC.csv</code></pre>
</div>

<!-- 🔹 Step 3: Read Trimming -->

## Step 3: Read Trimming

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

### Trimmomatic

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-trim-trimmomatic', this)">
  <strong>Run Trimming with Trimmomatic</strong>
</label>

<div id="cmd-trim-trimmomatic" class="step-command">
<pre><code>nextflow run main.nf --exec trim --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --trimmomatic --adapters polyA_polyG.fa</code></pre>
</div>

<!-- 🔸 fastp -->

### fastp

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-trim-fastp', this)">
  <strong>Run Trimming with fastp</strong>
</label>

<div id="cmd-trim-fastp" class="step-command">
<pre><code>nextflow run main.nf --exec trim --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --fastp --adapters polyA_polyG.fa </code></pre>
</div>
 
<!-- 🔸 BBDuk -->

### BBDuk

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-trim-bbduk', this)">
  <strong>Run Trimming with BBDuk</strong>
</label>

<div id="cmd-trim-bbduk" class="step-command">
<pre><code>nextflow run main.nf --exec trim --tobetrimmed CSVs/2_SamplesheetForTrimming.csv --bbduk --adapters polyA_polyG.fa</code></pre>
</div>
 

<!-- 🔹 Step 4: Reference Indexing -->

## Step 4: Index the Reference Genome

<div align="justify">  
This step prepares the reference genome by generating the necessary index files.  
You can either use your own FASTA file placed in the `Reference_Genome/` directory,  
or use the `--igenome` parameter to automatically download and index a standard reference genome.
</div>

---

### Local Reference

???+ note " 💡**Option 1**: Local FASTA"
    Use your own reference FASTA file.  
    Place it inside the `Reference_Genome/` directory and use the following command:

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-refidx-local', this)">
  <strong>Run Reference Indexing (with local FASTA)</strong>
</label>

<div id="cmd-refidx-local" class="step-command">
<pre><code>nextflow run main.nf --exec refidx --reference Reference_Genome/reference.fa</code></pre>
</div>

---

### iGenomes Reference

???+ note " 💡**Option 2**: Auto-download with iGenomes"
    Use the `--igenome` parameter to fetch and index a reference genome.  
    Example: `--igenome Ens.GRCh37`

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-refidx-igenome', this)">
  <strong>Run Reference Indexing (auto-download with iGenomes)</strong>
</label>

<div id="cmd-refidx-igenome" class="step-command">
<pre><code>nextflow run main.nf --exec refidx --igenome Ens.GRCh37</code></pre>
</div>

---

### Aligner Option

???+ note " 💡 **Aligner Customization**"
    The default aligner used is `bwa` for both the **indexing** and **alignment** steps.  
    To switch to `bwamem2`, simply add the `--aligner bwamem2` flag to the command.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-refidx-aligner', this)">
  <strong>Run Reference Indexing with BWA-MEM2</strong>
</label>

<div id="cmd-refidx-aligner" class="step-command">
<pre><code>nextflow run main.nf --exec refidx --reference Reference_Genome/reference.fa --aligner bwamem2</code></pre>
</div>

---

## Step 5: Alignment
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
<pre><code>nextflow run main.nf --exec align --reference Reference_Genome/reference.fa --tobealigned CSVs/3_samplesheetForAssembly.csv --aligner bwamem2 </code></pre>
</div>

---

## Step 6: Base Quality Score Recalibration

<div align="justify">
This step applies GATK's Best Practices for Base Quality Score Recalibration (BQSR).  
It adjusts the quality scores of sequencing reads using known variant sites to improve variant calling accuracy.  
You can either use your own VCF files or download reference sets automatically using the `--ivcf` parameters.
</div>

---

### Local Known Sites (VCF files)

???+ note " 💡 **Option 1**:"
    Use locally downloaded VCF files for known sites.  
    You must specify their paths using `--knownsite1` and `--knownsite2`.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-bqsr-local', this)">
  <strong>Run BQSR (with local known sites)</strong>
</label>

<div id="cmd-bqsr-local" class="step-command">
<pre><code>nextflow run main.nf --exec bqsr \
  --reference Reference_Genome/reference.fa \
  --bam CSVs/4_samplesheetForBamFiles.csv \
  --knownsite1 knownsites/1000g_gold_standard.indels.filtered.vcf \
  --knownsite2 knownsites/GCF.38.filtered.renamed.vcf</code></pre>
</div>

---

### Auto-Download Known Sites

???+ note " 💡 **Option 2**:"
    Use `--ivcf1` and `--ivcf2` to automatically download public known sites for BQSR.  
    Examples: `GRCh38.mills1000`, `GRCh38.dbsnp`.

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-bqsr-auto', this)">
  <strong>Run BQSR (auto-download known sites)</strong>
</label>

<div id="cmd-bqsr-auto" class="step-command">
<pre><code>nextflow run main.nf --exec bqsr \
    --reference Reference_Genome/reference.fa \
    --bam CSVs/4_samplesheetForBamFiles.csv \
    --ivcf1 GRCh38.mills1000 \
    --ivcf2 GRCh38.omni
</code></pre>
</div>

---

## Step 7: Variant Calling

<div align="justify">
This step performs variant calling using the final recalibrated BAM files.  
By default, it generates a VCF file for each patient, extracts a variant table, filters SNPs, and automatically creates per-sample GVCF files.  
You can modify the output behavior using the `--generate` flag:
</div>

---

### Default Mode

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
<pre><code>nextflow run main.nf --exec callsnp \
  --reference Reference_Genome/reference.fa \
  --tovarcall CSVs/5_samplesheetReclibFiles.csv</code></pre>
</div>

---

### Generate Only VCF & SNP Table

???+ note " 💡 **Option:** `--generate onlyVCF`"
    - Skips GVCF creation  
    - Outputs only the main VCF file, variant table, and SNP table

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-call-onlyvcf', this)">
  <strong>Run Variant Calling (only VCF + SNP)</strong>
</label>

<div id="cmd-call-onlyvcf" class="step-command">
<pre><code>nextflow run main.nf --exec callsnp \
  --reference Reference_Genome/reference.fa \
  --tovarcall CSVs/5_samplesheetReclibFiles.csv \
  --generate onlyVCF</code></pre>
</div>

---

### Generate Cohort GVCF

???+ note " 💡 **Option:** `--generate CohorteGVCF`"
    - Produces a single joint cohort `.g.vcf` file  
    - Useful for population-level variant analysis or joint genotyping

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-call-cohortgvcf', this)">
  <strong>Run Variant Calling (Cohort GVCF)</strong>
</label>

<div id="cmd-call-cohortgvcf" class="step-command">
<pre><code>nextflow run main.nf --exec callsnp \
  --reference Reference_Genome/reference.fa \
  --tovarcall CSVs/5_samplesheetReclibFiles.csv \
  --generate cohorteGVCF</code></pre>
</div>

## Step 8: Variant Annotation

This step adds functional information to your variants using **Ensembl VEP (Variant Effect Predictor)**.

---

### VEP Cache Downloading

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
<pre><code>nextflow run main.nf --exec vepcache --species homo_sapiens</code></pre>
</div>

 
??? warning "⚠️ Conda Limitation"
    When using the **conda** environment, only **VEP cache version 113** is available.
    To use a newer version (e.g., **114**), you must run with the **Docker profile**:
    
    ```
    nextflow run main.nf --exec vepcache --species homo_sapiens --assembly GRCh37 --cachetype refseq --cacheversion 114 -profile docker
    ```

<label>
  <input type="checkbox" onchange="toggleCommand('cmd-full-vep-cache', this)">
  <strong>Download VEP Cache</strong> with full arguments
</label>

<div id="cmd-full-vep-cache" class="step-command">
<pre><code>nextflow run main.nf --exec vepcache --species homo_sapiens --assembly GRCh37 --cachetype refseq --cacheversion 114 -profile docker</code></pre>
</div>

---

### VEP Annotation

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
<pre><code>nextflow main.nf --exec vepannotate \
  --toannotate CSVs/6_samplesheetvcfFiles.csv \
  --reference Reference_Genome/reference.fa \
  --species homo_sapiens \
  --assembly GRCh37 \
  --cachedir .vepcachedir/</code></pre>
</div>


