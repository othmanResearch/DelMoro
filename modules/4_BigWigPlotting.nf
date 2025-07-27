// Module files for DelMoro pipeline

// GENERATE BIGWIG PLOTS FROM BigWig FILES

process BigWigCoveragePlots {
    tag "BIGWIG PLOTS FOR ${bigWigFile}"
    publishDir "${params.outdir}/Mapping/coveragePlots/${bigWigFile.baseName}/", mode: 'copy'

    input:
    path bigWigFile

    output:
    path "*.png", emit: plots
    script:
    """
    #!/usr/bin/env python3
    import pyBigWig
    import matplotlib.pyplot as plt
    import numpy as np
    import os
    from tqdm import tqdm  # For progress bars

    def detect_chrom_naming(bw):
        #Auto-detect chromosome naming convention (with/without 'chr' prefix)#
        chroms = list(bw.chroms().keys())
        if any(c.startswith('chr') for c in chroms):
            return 'chr'
        return 'no_chr'

    def plot_coverage(bigWigFile,  autobin=True, min_coverage=0.1):
        # Generate coverage plots for all chromosomes in a BigWig file
        # Parameters:
        #   bigWigFile (str): Path to BigWig file
        #   output_dir (str): Output directory for plots
        #   autobin (bool): Auto-adjust bin size based on chromosome length
        #   min_coverage (float): Minimum coverage threshold for visualization

        # Retrieve bw file baseName
        basename = os.path.basename(bigWigFile).split(".")[0]

        try:
            # Open BigWig file
            bw = pyBigWig.open(bigWigFile)
            if not bw:
                raise RuntimeError(f"Could not open BigWig file: {bigWigFile}")

            # Detect naming convention
            naming_conv = detect_chrom_naming(bw)
            print(f"Chromosome naming: {'chr-prefixed' if naming_conv == 'chr' else 'unprefixed'}")

            # Process each chromosome
            for chrom in tqdm(bw.chroms(), desc='Processing chromosomes'):
                # Skip random/unlocalized contigs
                if '_' in chrom:
                    continue

                chrom_length = bw.chroms()[chrom]
                is_mt = chrom in ['MT', 'chrMT', 'M', 'chrM']

                # Special handling for mitochondrial DNA
                if is_mt:
                    # High-resolution MT plot (per-base)
                    try:
                        values = bw.values(chrom, 0, chrom_length)
                        if values is None:
                            print(f"\\nNo data for {chrom}")
                            continue

                        # Process values
                        values = np.nan_to_num(values, nan=0)
                        values[values < min_coverage] = 0
                        positions = np.arange(chrom_length)

                        # Create MT plot
                        plt.figure(figsize=(12, 4))
                        plt.plot(positions, values, 'b-', linewidth=0.8, alpha=0.8)
                        plt.title(f"Mitochondrial Genome Coverage\\n{chrom} (0-{chrom_length} bp)", pad=20)
                        plt.xlabel("Genomic Position (bp)")
                        plt.ylabel("Coverage Depth")
                        plt.grid(alpha=0.15, linestyle='--')
                        plt.tight_layout()

                        # Save plot
                        output_file = f"{basename}_coverage_{chrom}.png"
                        plt.savefig(output_file, dpi=300, bbox_inches='tight')
                        plt.close()
                        continue

                    except Exception as e:
                        print(f"\\nError processing {chrom}: {str(e)}")
                        continue

                # Standard chromosome processing
                bin_size = 1000 if autobin and chrom_length < 1e6 else (
                          5000 if autobin and chrom_length < 10e6 else 100000)

                starts = np.arange(0, chrom_length, bin_size)
                ends = starts + bin_size
                ends[-1] = chrom_length

                # Fetch coverage data
                positions = []
                coverage = []
                for s, e in zip(starts, ends):
                    mean_cov = bw.stats(chrom, s, e, type="mean")[0]
                    mean_cov = mean_cov if mean_cov is not None else 0
                    mean_cov = max(mean_cov, min_coverage)  # Apply threshold
                    positions.append(s)
                    coverage.append(mean_cov)

                # Create plot
                plt.figure(figsize=(20, 5))
                plt.plot(positions, coverage, 'b-', linewidth=0.7, alpha=0.9)

                # Formatting
                title_chrom = chrom if naming_conv == 'chr' else f'chr{chrom}'
                plt.title(f"Coverage on {title_chrom} ({bin_size//1000} Kb bins)", pad=15, fontsize=14)
                plt.xlabel("Genomic Position (bp)", fontsize=12)
                plt.ylabel("Coverage Depth", fontsize=12)
                plt.grid(alpha=0.1, linestyle=':')
                plt.tight_layout()

                # Save plot
                output_file = f"{basename}_coverage_{chrom}.png"
                plt.savefig(output_file, dpi=150, bbox_inches='tight')
                plt.close()

        except Exception as e:
            print(f"\\nFatal error: {str(e)}")
        finally:
            if 'bw' in locals():
                bw.close()
            print("\\nProcessing complete!")

    # Run the plotting function with default parameters
    plot_coverage("${bigWigFile}")
    """
}

