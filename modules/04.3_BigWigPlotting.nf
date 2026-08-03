// Module files for DelMoro pipeline

// GENERATE BIGWIG PLOTS FROM BigWig FILES

process BigWigCoveragePlots {
    tag "BIGWIG PLOTS FOR ${bigWigFile}"
    publishDir { "${params.outdir}/Mapping/coveragePlots/${bigWigFile.baseName}/" }, mode: 'copy', pattern: "*.png", enabled: params.saveImg
    publishDir "${params.outdir}/Mapping/coverageSummaryHtmls/", mode: 'copy', pattern: "*.html"

    conda "bioconda::pybigwig=0.3.22 matplotlib=3.10.3 conda-forge::numpy=1.26.4 conda-forge::tqdm=4.67.1"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/pybigwig-tools:1.1"
        : "firaszemzem/pybigwig-tools:1.1"}"

    input:
    tuple val(patient_id), path(bigWigFile)
    val mindepth
    val saveImg

    output:
    tuple val(patient_id), path("*.html"), emit: stats
    tuple val(patient_id), path("*.png"), optional: true

    script:
    """
    #!/usr/bin/env python3
    import pyBigWig
    import numpy as np
    import os
    from tqdm import tqdm
    from datetime import datetime
    import plotly.graph_objs as go
    from plotly.offline import plot

    try:
        import kaleido
    except ImportError:
        if ${saveImg}:
            raise ImportError("Install 'kaleido' to enable PNG export: pip install kaleido")

    def is_mitochondrial(chrom):
        return chrom in ['MT', 'chrMT', 'M', 'chrM']

    def generate_html_report(stats, basename, plot_divs, mindepth, outdir):
        output_file = f"{basename}_Summary-stats.html"
        html = f'''
        <html>
        <head>
            <title>Coverage Statistics - {basename}</title>
            <script src="https://cdn.plot.ly/plotly-latest.min.js"></script>
            <style>
                body {{ font-family: Arial, sans-serif; margin: 20px; }}

                .header {{
                    display: flex;
                    align-items: center;
                    margin-bottom: 20px;
                }}
                .header img {{
                    height: 60px;
                    margin-right: 20px;
                }}
                .header h1 {{
                    margin: 0;
                    font-size: 28px;
                    color: #2c3e50;
                }}
                .run-info {{
                    background-color: #f9f9f9;
                    border-left: 4px solid #4CAF50;
                    padding: 10px;
                    font-family: monospace;
                    margin-bottom: 30px;
                }}
                table {{
                    border-collapse: collapse;
                    width: 100%;
                    margin-bottom: 40px;
                }}
                th, td {{
                    border: 1px solid #ccc;
                    padding: 8px;
                    text-align: left;
                }}
                tr:nth-child(even) {{
                    background-color: #f2f2f2;
                }}
                th {{
                    background-color: #4CAF50;
                    color: white;
                }}
            </style>
        </head>
        <body>
            <div class="header">
                <img src="../../../.delmoro.png" alt="DelMoro Logo">
                <h1>DelMoro - Coverage Report - ${bigWigFile.baseName}</h1>
            </div>

            <div class="run-info">
                <strong>Command :</strong> ${workflow.commandLine}<br>
                <strong>workDir :</strong> ${workflow.workDir}<br>
            </div>

            <p>Generated on {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}</p>
            <p>Minimum coverage threshold: {mindepth}</p>
            <h2>Summary</h2>
            <table>
                <tr><th>Metric</th><th>Value</th></tr>
                <tr><td>Mean Coverage</td><td>{stats['mean_coverage']:.2f}</td></tr>
                <tr><td>Median Coverage</td><td>{stats['median_coverage']:.2f}</td></tr>
                <tr><td>% Bases Covered (&#8805;${mindepth})</td><td>{stats['pct_covered']:.1f}%</td></tr>
            </table>

            <h2>Per-Chromosome Stats</h2>
            <table>
                <tr>
                    <th>Chromosome</th>
                    <th>Length</th>
                    <th>Mean Coverage</th>
                    <th>Median Coverage</th>
                    <th>% Covered (&#8805;${mindepth})</th>
                </tr>
        '''
        for chrom in stats['chromosomes']:
            html += f'''
                <tr>
                    <td>{chrom['name']}</td>
                    <td>{chrom['length']:,}</td>
                    <td>{chrom['mean_coverage']:.2f}</td>
                    <td>{chrom['median_coverage']:.2f}</td>
                    <td>{chrom['pct_covered']:.1f}%</td>
                </tr>
            '''
        html += "</table><h2>Coverage Plots</h2>"
        for div in plot_divs:
            html += div
        html += "</body></html>"

        with open(output_file, "w", encoding="utf-8") as f:
            f.write(html)
        print(f"HTML report written to: {output_file}")

    def plot_coverage(bigWigFile, min_coverage=0.1, saveImg=False):
        basename = os.path.basename(bigWigFile).split(".")[0]
        stats = {'total_bases': 0, 'covered_bases': 0, 'chromosomes': []}
        plot_divs = []

        try:
            bw = pyBigWig.open(bigWigFile)
            if not bw or bw.chroms() == {}:
                raise ValueError("BigWig file is empty or invalid.")

            for chrom in tqdm(bw.chroms(), desc='Processing chromosomes'):
                chrom_length = bw.chroms()[chrom]
                is_mt = is_mitochondrial(chrom)
                bin_size = 1 if is_mt else (1000 if chrom_length < 1e6 else (5000 if chrom_length < 10e6 else 100000))

                starts = np.arange(0, chrom_length, bin_size)
                ends = np.minimum(starts + bin_size, chrom_length)
                coverage = [bw.stats(chrom, s, e, type="mean")[0] or 0 for s, e in zip(starts, ends)]
                positions = starts
                coverage_arr = np.array(coverage)

                chrom_stats = {
                    'name': chrom,
                    'length': chrom_length,
                    'mean_coverage': np.mean(coverage_arr),
                    'median_coverage': np.median(coverage_arr),
                    'pct_covered': np.mean(coverage_arr > min_coverage) * 100
                }

                stats['chromosomes'].append(chrom_stats)
                stats['total_bases'] += len(coverage_arr)
                stats['covered_bases'] += np.sum(coverage_arr > min_coverage)

                # Traces
                trace_above = go.Scatter(
                    x=[p for p, c in zip(positions, coverage) if c >= min_coverage],
                    y=[c for c in coverage if c >= min_coverage],
                    mode='lines', name=f"&#8805; {min_coverage}",
                    line=dict(color='#51d93f'), fill='tozeroy', fillcolor='rgba(0,0,255,0.1)'
                )
                trace_below = go.Scatter(
                    x=[p for p, c in zip(positions, coverage) if c < min_coverage],
                    y=[c for c in coverage if c < min_coverage],
                    mode='lines', name=f"< {min_coverage}",
                    line=dict(color='red'), fill='tozeroy', fillcolor='rgba(255,0,0,0.1)'
                )
                # Combine filtered points back in order
                all_points = sorted(
                    [(p, c) for p, c in zip(positions, coverage)],
                    key=lambda x: x[0]
                )
                x_all = [p for p, c in all_points]
                y_all = [c for p, c in all_points]

                trace_all = go.Scatter(
                    x=x_all,
                    y=y_all,
                    mode='lines',
                    name="All",
                    line=dict(color='blue', width=2)
                )

                threshold_line = go.Scatter(
                    x=[positions[0], positions[-1]],
                    y=[min_coverage]*2,
                    mode='lines',
                    name='Threshold',
                    line=dict(color='black', dash='dash')
                )

                fig = go.Figure(
                data=[trace_above, trace_all,trace_below, threshold_line],
                    layout=go.Layout(
                        title=f"Coverage Plot: {chrom}",
                        xaxis=dict(title='Genomic Position'),
                        yaxis=dict(title='Coverage'),
                        height=400,
                        hovermode='x'
                    )
                )

                div = plot(fig, output_type='div', include_plotlyjs=False)
                plot_divs.append(div)

                if saveImg:
                    fig.write_image(f"{basename}_{chrom}-coverage.png")

            stats['mean_coverage'] = np.mean([c['mean_coverage'] for c in stats['chromosomes']])
            stats['median_coverage'] = np.median([c['median_coverage'] for c in stats['chromosomes']])
            stats['pct_covered'] = (stats['covered_bases'] / stats['total_bases']) * 100

            generate_html_report(stats, basename, plot_divs, min_coverage, outdir=os.path.dirname(bigWigFile))

        except Exception as e:
            print(f"Fatal error: {e}")
            raise
        finally:
            if 'bw' in locals():
                bw.close()
            print("Processing complete.")

    plot_coverage("${bigWigFile}", ${mindepth}, ${saveImg ? 'True' : 'False'})
    """
}
