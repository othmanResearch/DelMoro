## Workflow Structure 
<div style="text-align: justify;">
<b>DelMoro</b> is a versatile genomic analysis pipeline offering two distinct operational modes <b>stepmode</b> and <b>fullmode</b> to balance <b>analytical flexibility</b> with <b>automation efficiency</b>.  
This dual-structure design supports both <b>granular, stage-specific control</b> and <b>end-to-end streamlined processing</b>, making it suitable for a wide range of research contexts, from exploratory bioinformatics to <b>clinical-grade variant analysis</b>.
</div>

---

- ![pipelineDelMoro.png](img/pipelineDelMoro.png) 
 
---

### 1. Stepmode
**Stepmode** decomposes the workflow into **eight discrete, sequential subworkflows**, allowing users to execute, customize, and refine each stage independently.

#### Subworkflows
1. **Raw Read Quality Control** – Assess sequencing read quality prior to downstream processing.
2. **Adapter Trimming** – Remove sequencing adapters using a selectable trimming algorithm.
3. **Reference Genome Indexing** – Prepare genome index files for efficient alignment.
4. **Read Alignment** – Map reads to the reference genome using **BWA** or **BWA-MEM2**.
5. **Base Quality Score Recalibration (BQSR)** – Adjust quality scores for improved variant calling accuracy.
6. **Variant Calling** – Identify genomic variants from aligned reads.
7. **Functional Annotation** – Interpret variants with an annotation process split into:
   - **Cache Preparation** (for reproducibility and offline use)
   - **Variant Annotation** (functional characterization of variants)
8. **Report Generation** – Produce summaries, metrics, and optional **depth-coverage visualizations**.

#### Key Features
- **Fine-grained control** over each step.
- **Method selection** (e.g., trimming algorithms, alignment tools).
- **Optional outputs** (e.g., coverage depth plots).
- **Isolated execution** of individual components for:
  - Method optimization
  - Troubleshooting
  - Partial reanalysis without reprocessing entire datasets

---

### 2. Fullmode
**Fullmode** consolidates all pipeline steps into a **single, integrated execution**, ensuring maximum automation while preserving configurable parameters.

#### Characteristics
- **End-to-end processing** from raw reads to final annotated report.
- Configurable parameters for:
  - Reference genome sourcing
  - Alignment methodology (**BWA** or **BWA-MEM2**)
  - Optional BQSR inclusion
- Ideal for **large-scale, high-throughput** studies.

---

## Choosing Between Modes

| Feature                | Stepmode  | Fullmode |
|------------------------|-----------|---------|
| Execution Control      | High      | High      |
| Customization          | High      | High      |
| Automation Level       | Low       | High      |
| Partial Reanalysis     | ✅         | ❌       |
| Throughput Efficiency  | Moderate  | High      |

---
## Workflow Adaptability & Example Use Cases
 
**Stepmode** is best suited for **iterative refinement** and **developmental genomics**, where individual stages may require repeated tweaking.  
Typical use cases include:
- Testing or rechecking multiple samples without re-running upstream processes.
- Adjusting trimming thresholds for challenging datasets.
- Re-annotating variants with updated databases.

**Fullmode** is optimized for **production-grade, reproducible analyses** with minimal manual intervention.  
Typical use cases include:
- Clinical pipelines requiring standardized, reproducible runs.
- Population-scale variant discovery projects.
- High-throughput genomics where automation is critical.

**Both modes** support:

- **Single-sample** and **cohort-based** studies

- **Parameter flexibility** at critical processing stages

- **Reproducibility** through structured workflows
1
