# Configuration File

 
## Using a `params.json` File

<div style="text-align: justify;">
  <p>In this section, we'll show you how to configure your Nextflow pipeline using a <code>params.json</code> file. This file lets you define key parameters such as resource allocation, input files, and options for each step of the pipeline. It's a simple, flexible way to customize the pipeline based on your datasets and specific use cases.</p>

  <p>To set up the pipeline, you’ll need to create a <code>params.json</code> file in the root directory of your project. Nextflow will automatically parse this file to set the values of various parameters throughout the pipeline. Below is a recommended template for the <code>params.json</code> file:</p>
</div>

---

### `params.json` Template

```json
{
  "cpus": 8,
  "outdir": "outdir",
  
  "basedon": "./CSVs/1_samplesheetForRawQC.csv",  

  "_comment": "For reference indexing use either 'reference' or 'igenome'",

  "reference": "./Reference_Genome/genomeEns.GRCh37.fa",
  "igenome"	: "Ens.GRCh37",

  "_comment": "Choose the aligner; options are 'null' or 'bwamem2'",

  "aligner": "bwamem2",  
  
  "rawreads": "./CSVs/1_samplesheetForRawQC.csv",         
  "tobetrimmed": "./CSVs/2_SamplesheetForTrimming.csv",         
  "tobealigned": "./CSVs/3_samplesheetForAssembly.csv",         
  "bam": "./CSVs/4_samplesheetForBamFiles.csv",
  "tovarcall": "./CSVs/5_samplesheetReclibFiles.csv",    
  "toannotate": "./CSVs/6_samplesheetvcfFiles.csv",  
  
  "_comment": "For base recalibration, use either knownSite1 & knownSite2 or ivcf1 & ivcf2",
  
  "knownsite1": "./knownsites/1000g_gold_standard.indels.filtered.vcf",     
  "knownsite2": "./knownsites/GCF.38.filtered.renamed.vcf",  
  
  "ivcf1": "GRCh38.mills1000",     
  "ivcf2": "GRCh38.omni"
}
```

---
## Csv files Templates

<div style="text-align: justify;">
The following CSV structure templates are integral to the pipeline, defining standardized input and output formats across each processing stage — from raw read quality control to variant calling. Their consistent use ensures data integrity, reproducibility, and streamlined automation throughout the workflow.
<br><br>
</div>

To automatically generate all required CSV files as part of the setup, consult the 🔗 [How to Initialize the Pipeline](running.md#step-1-initialize-the-pipeline)




<!-- 🔸 CSV Templates -->
### RawQc csv Template

???+ note "💡 **1_samplesheetForRawQC.csv**"
    Header: `patient_id,R1,R2`
    ```csv
    patient_id,R1,R2
    41TNS1,./Data/father_1.fastq.gz,./Data/father_2.fastq.gz
    2TNS12,./Data/mother_1.fastq.gz,./Data/mother_2.fastq.gz
    3TNS13,./Data/son_1.fastq.gz,./Data/son_2.fastq.gz
    ```

### Trimming csv Template

???+ note "💡 **2_SamplesheetForTrimming.csv**"
    Header: `patient_id,R1,R2,MINLEN,LEADING,TRAILING,SLIDINGWINDOW`
    ```csv
    41TNS1,./Data/father_1.fastq.gz,./Data/father_2.fastq.gz,36,30,30,4:20
    2TNS12,./Data/mother_1.fastq.gz,./Data/mother_2.fastq.gz,36,30,30,4:20
    3TNS13,./Data/son_1.fastq.gz,./Data/son_2.fastq.gz,36,30,30,4:20
    ```
### Alignment csv Template

???+ note "💡 **3_samplesheetForAssembly.csv**"
    Header: `patient_id,R1,R2`
    ```csv
    41TNS1,./outdir/TrimmedREADS/41TNS1_1.trim.fastq.gz,./outdir/TrimmedREADS/41TNS1_2.trim.fastq.gz
    2TNS12,./outdir/TrimmedREADS/2TNS12_1.trim.fastq.gz,./outdir/TrimmedREADS/2TNS12_2.trim.fastq.gz
    3TNS13,./outdir/TrimmedREADS/3TNS13_1.trim.fastq.gz,./outdir/TrimmedREADS/3TNS13_2.trim.fastq.gz
    ```

### Bam files csv Template

???+ note "💡 **4_samplesheetForBamFiles.csv**"
    Header: `patient_id,BamFile`
    ```csv
    41father,./outdir/Mapping/41father_delMoro.bam
    22mother,./outdir/Mapping/22mother_delMoro.bam
    33son,./outdir/Mapping/33son_delMoro.bam
    ```

### Recalibrated Bam files csv Template

???+ note "💡 **5_samplesheetReclibFiles.csv**"
    Header: `patient_id,BamFile`
    ```csv
    41TNS1,./outdir/Mapping/41TNS1.recal.bam
    2TNS12,./outdir/Mapping/2TNS12.recal.bam
    3TNS13,./outdir/Mapping/3TNS13.recal.bam
    ```

### Vcf files csv Template

???+ note "💡 **6_samplesheetvcfFiles.csv**"
    Header: `patient_id,vcFile`
    ```csv
    41TNS1,./outdir/Mapping/Variants/41TNS1_sor_RG_MD.bam.recal.HC.vcf
    2TNS12,./outdir/Mapping/Variants/2TNS12_sor_RG_MD.bam.recal.HC.vcf
    3TNS13,./outdir/Mapping/Variants/3TNS13_sor_RG_MD.bam.recal.HC.vcf
    ```
