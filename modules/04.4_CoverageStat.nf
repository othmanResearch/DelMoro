// Module files for DelMoro pipeline

// GENERATES A COVERAGE FILE IN BED FORMAT

process BamCoverage {
    tag "GENERATES BAM COVERAGE"
    publishDir "${params.outdir}/Mapping/BamCoverage/", mode: 'copy'

    conda "bioconda::bamtocov=2.7.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"
        : "quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"}"

    input:
    tuple val(patient_id), path(BamFile), path(bamidx)
    path bedtarget    
    
    output:
    tuple val(patient_id), path("*_coverage.bed")

    script:
    def prefix = BamFile.baseName.takeWhile { it != '_' }
    def outfile = (bedtarget.name == "NO_FILE") ? "${prefix}_coverage.bed" : "${prefix}_${bedtarget.baseName}_coverage.bed"
    def target_option = (bedtarget.name == "NO_FILE") ? "" : "-r ${bedtarget}"
    
    """
    echo -e "Chromosome\tStart\tEnd\tCoverage" > ${outfile}
    bamtocov ${target_option} ${BamFile} >> ${outfile}
    """
}

// GENERATE A HTML REPORT FROM THE BED COVERAGE FILE
///////////////////////:


process BamCoveReport {

    tag "GENERATE A HTML REPORT FROM THE BED COVERAGE FILE"
    publishDir "${params.outdir}/Mapping/BamCoverage/", mode: 'copy'

    input:
    tuple val(patient_id), path(bedcov)
    path(bedtarget)

    output:
    tuple val(patient_id), path("*_coverage.html"), emit: covHtml
    tuple val(patient_id), path("*_coverage.csv"), emit: covCsv

    script:
    def prefix = bedcov.baseName.takeWhile { it != '_' }
    def outfile = (bedtarget.name == "NO_FILE") ? "${prefix}_coverage.html" : "${prefix}_${bedtarget.baseName}_coverage.html"
    def csvfile = (bedtarget.name == "NO_FILE") ? "${prefix}_coverage.csv" : "${prefix}_${bedtarget.baseName}_coverage.csv"
    def target_file = bedtarget.name == "NO_FILE" ? "None" : "\"${bedtarget}\""
    """
    #!/usr/bin/env python

    import argparse
    import html
    from collections import defaultdict
    from datetime import datetime

    THRESHOLDS = [1, 10, 20, 30, 50, 100]


    def create_accumulator():
        return {
            "total_bases": 0,
            "depth_bases": 0.0,
            "threshold_bases": {threshold: 0 for threshold in THRESHOLDS},
            "depth_histogram": defaultdict(int),
        }


    def add_depth(accumulator, length, depth):
        accumulator["total_bases"] += length
        accumulator["depth_bases"] += length * depth
        accumulator["depth_histogram"][depth] += length

        for threshold in THRESHOLDS:
            if depth >= threshold:
                accumulator["threshold_bases"][threshold] += length


    # ============================================================
    # TARGET BED
    # ============================================================

    def read_target_bed(filename):
        # Read target BED.
        # Expected:
        #     chrom start end
        # Additional columns are ignored.
        # Overlapping/adjacent target intervals are merged.

        targets = defaultdict(list)

        with open(filename, "r", encoding="utf-8") as fh:
            for line_number, line in enumerate(fh, 1):
                line = line.strip()

                if not line:
                    continue

                if line.startswith("#"):
                    continue

                fields = line.split()

                if len(fields) < 3:
                    raise ValueError(
                        f"Invalid target BED line {line_number}: "
                        f"expected at least 3 columns"
                    )

                # Common header
                if (
                    fields[0].lower() in {"chrom", "chromosome"}
                    and fields[1].lower() == "start"
                    and fields[2].lower() == "end"
                ):
                    continue

                chrom = fields[0]

                try:
                    start = int(fields[1])
                    end = int(fields[2])
                except ValueError as e:
                    raise ValueError(
                        f"Invalid target coordinates on line {line_number}: {line}"
                    ) from e

                if start < 0:
                    raise ValueError(
                        f"Negative target coordinate on line {line_number}: {line}"
                    )

                if end <= start:
                    raise ValueError(
                        f"Invalid target interval on line {line_number}: {line}"
                    )

                targets[chrom].append((start, end))

        # --------------------------------------------------------
        # Sort and merge overlapping/adjacent targets
        # --------------------------------------------------------

        merged_targets = {}

        for chrom, intervals in targets.items():
            intervals.sort()

            merged = []

            for start, end in intervals:
                if merged and start <= merged[-1][1]:
                    merged[-1] = (merged[-1][0], max(merged[-1][1], end))
                else:
                    merged.append((start, end))

            merged_targets[chrom] = merged

        return merged_targets


    def calculate_target_territory(targets):
        total = 0

        for intervals in targets.values():
            for start, end in intervals:
                total += end - start

        return total


    # ============================================================
    # FINALIZE STATISTICS
    # ============================================================

    def finalize_statistics(accumulator):
        total_bases = accumulator["total_bases"]

        if total_bases == 0:
            return {
                "total_bases": 0,
                "mean_depth": 0.0,
                "median_depth": 0.0,
                "pct_0x": 0.0,
                "pct_lt10x": 0.0,
                "pct_lt20x": 0.0,
                "pct_1x": 0.0,
                "pct_10x": 0.0,
                "pct_20x": 0.0,
                "pct_30x": 0.0,
                "pct_50x": 0.0,
                "pct_100x": 0.0,
            }

        # --------------------------------------------------------
        # Mean
        # --------------------------------------------------------

        mean_depth = accumulator["depth_bases"] / total_bases

        # --------------------------------------------------------
        # Weighted median
        # --------------------------------------------------------

        midpoint = total_bases / 2

        cumulative = 0

        median_depth = 0.0

        for depth in sorted(accumulator["depth_histogram"]):
            cumulative += accumulator["depth_histogram"][depth]

            if cumulative >= midpoint:
                median_depth = depth
                break

        # --------------------------------------------------------
        # Threshold percentages
        # --------------------------------------------------------

        pct = {}

        for threshold in THRESHOLDS:
            covered = accumulator["threshold_bases"][threshold]
            pct[threshold] = covered / total_bases * 100

        return {
            "total_bases": total_bases,
            "mean_depth": mean_depth,
            "median_depth": median_depth,
            "pct_0x": max(0.0, 100.0 - pct[1]),
            "pct_lt10x": max(0.0, 100.0 - pct[10]),
            "pct_lt20x": max(0.0, 100.0 - pct[20]),
            "pct_1x": pct[1],
            "pct_10x": pct[10],
            "pct_20x": pct[20],
            "pct_30x": pct[30],
            "pct_50x": pct[50],
            "pct_100x": pct[100],
        }


    # ============================================================
    # COVERAGE PROCESSING
    # ============================================================

    def process_coverage_file(coverage_file, targets=None):
        # Process coverage BED.
        # If targets is None:
        #     use every coverage interval.
        # If targets is supplied:
        #     intersect coverage with target intervals.

        overall = create_accumulator()
        chromosome_data = defaultdict(create_accumulator)

        # --------------------------------------------------------
        # Target mode
        # --------------------------------------------------------

        target_index = defaultdict(int)

        # --------------------------------------------------------
        # Coverage file
        # --------------------------------------------------------

        with open(coverage_file, "r", encoding="utf-8") as fh:
            for line_number, line in enumerate(fh, 1):
                line = line.strip()

                if not line:
                    continue

                if line.startswith("#"):
                    continue

                fields = line.split()

                if len(fields) < 4:
                    raise ValueError(
                        f"Invalid coverage line {line_number}: "
                        f"expected at least 4 columns"
                    )

                # Header
                if (
                    fields[0].lower() == "chromosome"
                    and fields[1].lower() == "start"
                    and fields[2].lower() == "end"
                    and fields[3].lower() in {"coverage", "depth"}
                ):
                    continue

                chrom = fields[0]

                try:
                    start = int(fields[1])
                    end = int(fields[2])
                    depth = float(fields[3])
                except ValueError as e:
                    raise ValueError(
                        f"Invalid coverage values on line {line_number}: {line}"
                    ) from e

                if start < 0:
                    raise ValueError(
                        f"Negative coverage start on line {line_number}: {line}"
                    )

                if end < start:
                    raise ValueError(
                        f"Invalid coverage interval on line {line_number}: {line}"
                    )

                if end == start:
                    continue

                if depth < 0:
                    raise ValueError(
                        f"Negative coverage on line {line_number}: {depth}"
                    )

                # =================================================
                # MODE 1: No target BED
                # =================================================

                if targets is None:
                    length = end - start

                    add_depth(overall, length, depth)
                    add_depth(chromosome_data[chrom], length, depth)

                    continue

                # =================================================
                # MODE 2: Target BED supplied
                # =================================================

                if chrom not in targets:
                    continue

                chrom_targets = targets[chrom]

                i = target_index[chrom]

                # Skip targets before coverage interval
                while i < len(chrom_targets) and chrom_targets[i][1] <= start:
                    i += 1

                target_index[chrom] = i

                # ------------------------------------------------
                # Intersect coverage with targets
                # ------------------------------------------------

                while i < len(chrom_targets) and chrom_targets[i][0] < end:
                    target_start, target_end = chrom_targets[i]

                    overlap_start = max(start, target_start)
                    overlap_end = min(end, target_end)

                    if overlap_end > overlap_start:
                        length = overlap_end - overlap_start

                        add_depth(overall, length, depth)
                        add_depth(chromosome_data[chrom], length, depth)

                    if target_end <= end:
                        i += 1
                        target_index[chrom] = i
                    else:
                        break

        return overall, chromosome_data


    # ============================================================
    # CSV REPORT
    # ============================================================

    def csv_escape(value):
        value = str(value)
        if any(char in value for char in [",", '"', "\\n", "\\r"]):
            return '"' + value.replace('"', '""') + '"'
        return value



    def generate_csv_report(
        output_file,
        input_file,
        target_file,
        target_territory,
        overall,
        chromosome_stats,
        target_mode,
    ):
        rows = []

        def add_row(scope, chromosome, metric, value, unit):
            rows.append([
                scope,
                chromosome,
                metric,
                value,
                unit,
            ])

        # Overall metrics
        add_row("overall", "", "Bases evaluated", overall["total_bases"], "bp")
        add_row("overall", "", "Mean depth", f"{overall['mean_depth']:.2f}", "x")
        add_row("overall", "", "Median depth", f"{overall['median_depth']:.2f}", "x")
        add_row("overall", "", "0×", f"{overall['pct_0x']:.2f}", "%")
        add_row("overall", "", "<10×", f"{overall['pct_lt10x']:.2f}", "%")
        add_row("overall", "", "<20×", f"{overall['pct_lt20x']:.2f}", "%")
        add_row("overall", "", "≥1×", f"{overall['pct_1x']:.2f}", "%")
        add_row("overall", "", "≥10×", f"{overall['pct_10x']:.2f}", "%")
        add_row("overall", "", "≥20×", f"{overall['pct_20x']:.2f}", "%")
        add_row("overall", "", "≥30×", f"{overall['pct_30x']:.2f}", "%")
        add_row("overall", "", "≥50×", f"{overall['pct_50x']:.2f}", "%")
        add_row("overall", "", "≥100×", f"{overall['pct_100x']:.2f}", "%")

        # Per-chromosome metrics
        for chrom in sorted(chromosome_stats):
            stats = chromosome_stats[chrom]
            add_row("chromosome", chrom, "Bases evaluated", stats["total_bases"], "bp")
            add_row("chromosome", chrom, "Mean depth", f"{stats['mean_depth']:.2f}", "x")
            add_row("chromosome", chrom, "Median depth", f"{stats['median_depth']:.2f}", "x")
            add_row("chromosome", chrom, "0×", f"{stats['pct_0x']:.2f}", "%")
            add_row("chromosome", chrom, "≥10×", f"{stats['pct_10x']:.2f}", "%")
            add_row("chromosome", chrom, "≥20×", f"{stats['pct_20x']:.2f}", "%")
            add_row("chromosome", chrom, "≥30×", f"{stats['pct_30x']:.2f}", "%")
            add_row("chromosome", chrom, "≥50×", f"{stats['pct_50x']:.2f}", "%")
            add_row("chromosome", chrom, "≥100×", f"{stats['pct_100x']:.2f}", "%")

        with open(output_file, "w", encoding="utf-8", newline="") as fh:
            fh.write("# Coverage summary generated by BamCoveReport\\n")
            fh.write("# scope: overall or chromosome\\n")
            fh.write("# chromosome: chromosome name; empty for overall metrics\\n")
            fh.write("# metric: coverage statistic name (e.g. 0× - <10×- ≥20×)\\n")
            fh.write("# value: numeric metric value\\n")
            fh.write("# unit: bp- x (depth)- or % (percentage)\\n")
            fh.write("scope,chromosome,metric,value,unit\\n")
            for row in rows:
                fh.write(",".join(csv_escape(value) for value in row) + "\\n")


    # ============================================================
    # HTML REPORT
    # ============================================================
    def generate_html_report(
        output_file,
        input_file,
        target_file,
        target_territory,
        overall,
        chromosome_stats,
        target_mode,
        command_line=None,
        work_dir=None,
    ):
        generated = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

        if target_mode:
            analysis_description = "Coverage restricted to target/capture BED"
            target_display = html.escape(str(target_file))
            territory_display = f"{target_territory:,} bp"
        else:
            analysis_description = "All bases represented in coverage BED"
            target_display = "Not supplied"
            territory_display = f"{overall['total_bases']:,} bp"

        # --------------------------------------------------------
        # RUN INFORMATION
        # --------------------------------------------------------

        run_info = []
        run_info.append("<strong>Command:</strong> "+ html.escape(str(command_line)))
        run_info.append("<strong>Work directory:</strong> "+ html.escape(str(work_dir)))

        run_info.append("<strong>Coverage file:</strong> "+ html.escape(str(input_file)))
        run_info.append("<strong>Analysis:</strong> "+html.escape(str(analysis_description)))
        run_info.append("<strong>Target BED:</strong> "+ target_display)

        run_info.append("<strong>Bases evaluated:</strong> "+ territory_display)
        run_info.append("<strong>Generated:</strong> "+ generated)

        # IMPORTANT:
        # chr(10) avoids Nextflow/Groovy newline/interpolation problems
        run_info_html = "<br>".join(run_info)

        # --------------------------------------------------------
        # CHROMOSOME ROWS
        # --------------------------------------------------------

        chromosome_rows = []

        for chrom in sorted(chromosome_stats):

            stats = chromosome_stats[chrom]

            row = (
                "<tr>"
                "<td>" + html.escape(str(chrom)) + "</td>"
                "<td>" + f"{stats['total_bases']:,}" + "</td>"
                "<td>" + f"{stats['mean_depth']:.2f}" + "×</td>"
                "<td>" + f"{stats['median_depth']:.2f}" + "×</td>"
                "<td>" + f"{stats['pct_0x']:.2f}" + "%</td>"
                "<td>" + f"{stats['pct_10x']:.2f}" + "%</td>"
                "<td>" + f"{stats['pct_20x']:.2f}" + "%</td>"
                "<td>" + f"{stats['pct_30x']:.2f}" + "%</td>"
                "<td>" + f"{stats['pct_50x']:.2f}" + "%</td>"
                "<td>" + f"{stats['pct_100x']:.2f}" + "%</td>"
                "</tr>"
            )

            chromosome_rows.append(row)

        chromosome_rows_html = "".join(chromosome_rows)

        # --------------------------------------------------------
        # HTML
        # --------------------------------------------------------

        html_report = []

        html_report.append("<!DOCTYPE html>")
        html_report.append("<html>")
        html_report.append("<head>")
        html_report.append('<meta charset="UTF-8">')
        html_report.append(
            '<meta name="viewport" '
            'content="width=device-width, initial-scale=1.0">'
        )

        html_report.append(
            "<title>Coverage Statistics - "
            + html.escape(str(input_file))
            + "</title>"
        )

        # --------------------------------------------------------
        # CSS
        # --------------------------------------------------------

        html_report.append("<style>")

        html_report.append(
            "body {"
            "font-family: Arial, sans-serif;"
            "margin: 20px;"
            "color: #222;"
            "background-color: #fff;"
            "}"
        )

        html_report.append(
            ".header {"
            "display: flex;"
            "align-items: center;"
            "margin-bottom: 20px;"
            "}"
        )

        html_report.append(
            ".header img {"
            "height: 60px;"
            "margin-right: 20px;"
            "}"
        )

        html_report.append(
            ".header h1 {"
            "margin: 0;"
            "font-size: 28px;"
            "color: #2c3e50;"
            "}"
        )

        html_report.append(
            ".run-info {"
            "background-color: #f9f9f9;"
            "border-left: 4px solid #4CAF50;"
            "padding: 10px;"
            "font-family: monospace;"
            "margin-bottom: 30px;"
            "line-height: 1.7;"
            "}"
        )

        html_report.append(
            "table {"
            "border-collapse: collapse;"
            "width: 100%;"
            "margin-bottom: 40px;"
            "}"
        )

        html_report.append(
            "th, td {"
            "border: 1px solid #ccc;"
            "padding: 8px;"
            "text-align: left;"
            "}"
        )

        html_report.append(
            "tr:nth-child(even) {"
            "background-color: #f2f2f2;"
            "}"
        )

        html_report.append(
            "th {"
            "background-color: #4CAF50;"
            "color: white;"
            "}"
        )

        html_report.append(
            "h2 {"
            "color: #34495e;"
            "margin-top: 35px;"
            "}"
        )

        html_report.append(
            ".summary {"
            "background-color: #e8f5e9;"
            "border-left: 4px solid #2e7d32;"
            "padding: 15px;"
            "margin-bottom: 30px;"
            "line-height: 1.8;"
            "}"
        )

        html_report.append(
            ".warning {"
            "background-color: #fff3e0;"
            "border-left: 4px solid #ef6c00;"
            "padding: 15px;"
            "margin-top: 20px;"
            "margin-bottom: 30px;"
            "line-height: 1.7;"
            "}"
        )

        html_report.append(
            ".small {"
            "font-size: 13px;"
            "color: #666;"
            "}"
        )

        html_report.append("</style>")
        html_report.append("</head>")
        html_report.append("<body>")

        # --------------------------------------------------------
        # HEADER
        # --------------------------------------------------------

        html_report.append('<div class="header">')

        html_report.append(
            '<img src="../../../.delmoro.png" '
            'alt="DelMoro Logo">'
        )

        html_report.append(
            "<h1>"
            "DelMoro - Coverage Report - "
            + html.escape(str(input_file))
            + "</h1>"
        )

        html_report.append("</div>")

        # --------------------------------------------------------
        # RUN INFO
        # --------------------------------------------------------

        html_report.append('<div class="run-info">')
        html_report.append(run_info_html)
        html_report.append("</div>")

        # --------------------------------------------------------
        # OVERALL COVERAGE
        # --------------------------------------------------------

        html_report.append("<h2>Overall Coverage</h2>")
        html_report.append("<table>")

        html_report.append(
            "<tr>"
            "<th>Metric</th>"
            "<th>Value</th>"
            "</tr>"
        )

        metrics = [
            ("Bases evaluated", f"{overall['total_bases']:,}"),
            ("Mean Coverage", f"{overall['mean_depth']:.2f}×"),
            ("Median Coverage", f"{overall['median_depth']:.2f}×"),
            ("0× Coverage", f"{overall['pct_0x']:.2f}%"),
            ("&lt;10× Coverage", f"{overall['pct_lt10x']:.2f}%"),
            ("&lt;20× Coverage", f"{overall['pct_lt20x']:.2f}%"),
            ("≥1× Coverage", f"{overall['pct_1x']:.2f}%"),
            ("≥10× Coverage", f"{overall['pct_10x']:.2f}%"),
            ("≥20× Coverage", f"{overall['pct_20x']:.2f}%"),
            ("≥30× Coverage", f"{overall['pct_30x']:.2f}%"),
            ("≥50× Coverage", f"{overall['pct_50x']:.2f}%"),
            ("≥100× Coverage", f"{overall['pct_100x']:.2f}%"),
        ]

        for metric, value in metrics:
            html_report.append(
                "<tr>"
                "<td>" + metric + "</td>"
                "<td>" + value + "</td>"
                "</tr>"
            )

        html_report.append("</table>")

        # --------------------------------------------------------
        # WES SUMMARY
        # --------------------------------------------------------

        html_report.append("<h2>WES Coverage Summary</h2>")
        html_report.append('<div class="summary">')

        summary_items = [
            ("Mean depth", f"{overall['mean_depth']:.2f}×"),
            ("Median depth", f"{overall['median_depth']:.2f}×"),
            ("≥20×", f"{overall['pct_20x']:.2f}%"),
            ("≥30×", f"{overall['pct_30x']:.2f}%"),
            ("≥50×", f"{overall['pct_50x']:.2f}%"),
            ("≥100×", f"{overall['pct_100x']:.2f}%"),
            ("0×", f"{overall['pct_0x']:.2f}%"),
            ("&lt;10×", f"{overall['pct_lt10x']:.2f}%"),
        ]

        for label, value in summary_items:
            html_report.append(
                "<strong>"
                + label
                + ":</strong> "
                + value
                + "<br>"
            )

        html_report.append("</div>")

        # --------------------------------------------------------
        # PER-CHROMOSOME COVERAGE
        # --------------------------------------------------------

        html_report.append("<h2>Per-Chromosome Coverage</h2>")

        html_report.append(
            '<p class="small">'
            "When a target BED is provided, only target bases are "
            "included. When no target BED is provided, the statistics "
            "represent the coverage intervals contained in the "
            "coverage file."
            "</p>"
        )

        html_report.append("<table>")

        html_report.append(
            "<tr>"
            "<th>Chromosome</th>"
            "<th>Bases</th>"
            "<th>Mean</th>"
            "<th>Median</th>"
            "<th>0×</th>"
            "<th>≥10×</th>"
            "<th>≥20×</th>"
            "<th>≥30×</th>"
            "<th>≥50×</th>"
            "<th>≥100×</th>"
            "</tr>"
        )

        html_report.append(chromosome_rows_html)
        html_report.append("</table>")

        # --------------------------------------------------------
        # WARNING
        # --------------------------------------------------------

        html_report.append('<div class="warning">')

        html_report.append(
            "<strong>Interpretation:</strong><br>"
        )

        html_report.append(
            "For WES, target-restricted coverage is preferred "
            "when the capture/target BED is available."
        )

        html_report.append("<br><br>")

        html_report.append(
            "If no target BED is supplied, this report describes "
            "the bases represented by the supplied coverage file "
            "and should not be interpreted as a formal "
            "capture-target coverage metric."
        )

        html_report.append("</div>")

        # --------------------------------------------------------
        # END HTML
        # --------------------------------------------------------

        html_report.append("</body>")
        html_report.append("</html>")

       # Join HTML lines without using a literal backslash-n.
        html_report = chr(10).join(html_report) 

        # --------------------------------------------------------
        # WRITE
        # --------------------------------------------------------

        with open(output_file, "w", encoding="utf-8") as fh:
            fh.write(html_report)

        print()
        print("HTML report written to: " + output_file)
    # ============================================================
    # MAIN
    # ============================================================

    def main():
        coverage_file = "${bedcov}"
        output_file = "${outfile}"
        csv_output_file = "${csvfile}"
        command_line = "${workflow.commandLine}"
        work_dir = "${workflow.workDir}"
        
        if ${target_file} != None:
            target_file = ${target_file}
            targets = read_target_bed(target_file)
            target_territory = calculate_target_territory(targets)
            target_mode = True
        else:
            target_file = None
            targets = None
            target_territory = None
            target_mode = False

        overall_accumulator, chromosome_accumulators = process_coverage_file(
            coverage_file,
            targets,
        )
        overall = finalize_statistics(overall_accumulator)

        chromosome_stats = {}

        for chrom, accumulator in chromosome_accumulators.items():
            chromosome_stats[chrom] = finalize_statistics(accumulator)

        generate_html_report(
        output_file=output_file,
        input_file=coverage_file,
        target_file=target_file,
        target_territory=target_territory,
        overall=overall,
        chromosome_stats=chromosome_stats,
        target_mode=target_mode,
        command_line=command_line,
        work_dir=work_dir,
        )

        generate_csv_report(
        output_file=csv_output_file,
        input_file=coverage_file,
        target_file=target_file,
        target_territory=target_territory,
        overall=overall,
        chromosome_stats=chromosome_stats,
        target_mode=target_mode,
        )


    if __name__ == "__main__":
        main()
    """
}
