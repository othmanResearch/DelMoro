# Pipeline Tools

The following table summarizes the software components included in DelMoro pipeline along with the corresponding references that document their development and application.

| Pipeline Step | Tool | Full Mode | Step Mode | Citation |
|---------------|------|:---------:|:---------:|----------|
| **Raw Data Quality Control** | **FastQC** | ✓ | ✓ | Andrews S. *FastQC: A Quality Control Tool for High Throughput Sequence Data*. Babraham Bioinformatics (2010). |
| | **MultiQC** | ✓ | ✓ | Ewels P, Magnusson M, Lundin S, Käller M. *Bioinformatics*. **2016**;32(19):3047–3048. doi:10.1093/bioinformatics/btw354 |
| **Read Trimming** | **Trimmomatic** | ✓ | ✓ | Bolger AM, Lohse M, Usadel B. *Bioinformatics*. **2014**;30(15):2114–2120. doi:10.1093/bioinformatics/btu170 |
| | **fastp** | ✓ | ✓ | Chen S, Zhou Y, Chen Y, Gu J. *Bioinformatics*. **2018**;34:i884–i890. doi:10.1093/bioinformatics/bty560 |
| | **BBDuk** | ✓ | ✓ | Bushnell B. *BBMap: A Fast, Accurate, Splice-Aware Aligner*. (2014). |
| **Alignment** | **BWA-MEM** | ✓ | ✓ | Li H. *Aligning sequence reads, clone sequences and assembly contigs with BWA-MEM*. (2013). doi:10.48550/arXiv.1303.3997 |
| | **BWA-MEM2** | ✓ | ✓ | Vasimuddin M, Misra S, Li H, Aluru S. *IEEE International Parallel and Distributed Processing Symposium (IPDPS)*. **2019**. doi:10.1109/IPDPS.2019.00041 |
| **Alignment Metrics** | **CollectAlignmentSummaryMetrics** | ✓ | ✓ | Picard Toolkit (reference not included in bibliography). |
| | **CollectInsertSizeMetrics** | ✓ | ✓ | Picard Toolkit (reference not included in bibliography). |
| | **CollectGcBiasMetrics** | ✓ | ✓ | Picard Toolkit (reference not included in bibliography). |
| | **Qualimap 2** | ✓ | ✓ | Okonechnikov K, Conesa A, García-Alcalde F. *Bioinformatics*. **2016**;32(2):292–294. doi:10.1093/bioinformatics/btv566 |
| **Coverage Visualization** | **bamCoverage (deepTools2)** | ✓ | ✓ | Ramírez F, Ryan DP, Grüning B, et al. *Nucleic Acids Research*. **2016**;44(W1):W160–W165. doi:10.1093/nar/gkw257 |
| **BigWig Analysis & Plotting** | **pyBigWig** | ✓ | ✓ | [Python extension](https://github.com/deeptools/pyBigWig) |
| **Base Quality Score Recalibration** | **GATK BaseRecalibrator / ApplyBQSR** | ✓ | ✓ | McKenna A, Hanna M, Banks E, et al. *Genome Research*. **2010**;20:1297–1303. doi:10.1101/gr.107524.110 |
| **Variant Calling** | **GATK HaplotypeCaller** | ✓ | ✓ | Poplin R, Ruano-Rubio V, DePristo MA, et al. (2018). doi:10.1101/201178 |
| **Variant Filtering** | **GATK VariantFiltration** | ✓ | ✓ | McKenna A, Hanna M, Banks E, et al. *Genome Research*. **2010**;20:1297–1303. doi:10.1101/gr.107524.110 |
| **Variant Annotation** | **Variant Effect Predictor (VEP)** | ✓ | ✓ | McLaren W, Gil L, Hunt SE, et al. *Genome Biology*. **2016**;17:122. doi:10.1186/s13059-016-0974-4 |
| **Reporting** | **ReportLab** | ✓ | ✓ | [ReportLab Open Source Project](https://github.com/mattjmorrison/ReportLab) |
