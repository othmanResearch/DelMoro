// Module files for DelMoro pipeline

// Extract coverage bed from bam file
process ReportBamCov {
    tag "GENERATE BED COVERAGE FROM BAMS"
    publishDir "${params.outdir}/Reporting/BamCoverage/", mode: 'copy'

    conda "bioconda::bamtocov=2.7.0"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"
        : "quay.io/biocontainers/bamtocov:2.7.0--h6ead514_2"}"

    input:
    tuple val(patient_id), path(BamFile), path(bamidx)
    path bedtarget    
    
    output:
    tuple val(patient_id), path("*_coverage.bed"), emit: bedCov

    script:
    def prefix = BamFile.baseName.takeWhile { it != '_' }
    def outfile = (bedtarget.name == "NO_FILE") ? "${prefix}_coverage.bed" : "${prefix}_${bedtarget.baseName}_coverage.bed"
    def target_option = (bedtarget.name == "NO_FILE") ? "" : "-r ${bedtarget}"
    
    """
    echo -e "Chromosome\tStart\tEnd\tCoverage" > ${outfile}
    bamtocov ${target_option} ${BamFile} >> ${outfile}
    """
}

// Reporting Module with reportlab
process GenerateReports {
    tag "GeNERATE PDF REPORTS "
    publishDir "${params.outdir}/Reporting/", mode: 'copy'

    conda "reportlab=4.4.1 matplotlib=3.9.1 seaborn=0.13.2 pandas=2.3.1 numpy=1.26.4 qrcode=8.2"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/pyreportlab-toolkit:1.0"
        : "firaszemzem/pyreportlab-toolkit:1.0"}"

    input:
    tuple val(metadata), path(vcFile), path(delmorologo), val(metaYaml), path(bamBedFile) 
    path bedTaget

    output:
    path "${metadata.SampleID}.pdf"
    path "plots/${metadata.SampleID}/*.png"

    script:
    // Convert metaYaml to properly escaped JSON string
    def metaYamlJson = new groovy.json.JsonBuilder(metaYaml).toString().replace("'", "\\'")

    """
#!/usr/bin/env python

from reportlab.lib.pagesizes import letter
from reportlab.lib import colors
from reportlab.pdfgen import canvas
from reportlab.lib.units import inch
from reportlab.platypus import Table, TableStyle, Paragraph 
from reportlab.lib.styles import getSampleStyleSheet
coverage_styles = getSampleStyleSheet()
from datetime import datetime
import os
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
import qrcode
import gzip
import re
import json
from collections import defaultdict
import subprocess

##################################################################################

# Main script
# Define metadata (this should come from the Nextflow workflow)
metadata = {
    "SampleID": "${metadata.SampleID}",
    "Sex": "${metadata.Sex}",
    "Dob": "${metadata.Dob}",
    "Ethnicity": "${metadata.Ethnicity}",
    "Diagnosis": "${metadata.Diagnosis}",
    "Identifier": "${metadata.Identifier}"
}

# Define the DelMoro logo path (this should come from the Nextflow workflow)
delmorologo = "${delmorologo}"
vcFile = "${vcFile}"
bamBedFile = "${bamBedFile}"
bedTargetFile = "${bedTaget}"

# Create a directory for the sample plots
sample_plot_dir = f"plots/{metadata['SampleID']}"
os.makedirs(sample_plot_dir, exist_ok=True)

# Create a PDF file
pdf_file = f"{metadata['SampleID']}.pdf"
c = canvas.Canvas(pdf_file, pagesize=letter)
c.setTitle(f"DelMoro-Report-proband-{metadata['SampleID']}-{datetime.today().strftime('%Y-%m-%d')}")
# Define page dimensions
width, height = letter


# Parse the metaYaml JSON
try:
    metaYaml = json.loads('''${metaYamlJson}''')
except Exception as e:
    print(f"Error parsing metaYaml: {e}")
    metaYaml = {
        'physician': {'name': 'N/A', 'specialty': 'N/A', 'contact': {'email': 'N/A', 'phone': 'N/A'}, 'affiliation': 'N/A'},
        'institution': {'name': 'N/A', 'department': 'N/A', 'accreditation': 'N/A', 'address': {}},
        'hpo_terms': []
    }

##################################################################################

# Function to draw the header, patient info, and footer
def draw_header_to_footer(c, width, height, metadata, delmorologo):
    # Draw the header
    delmoro_text = [("Del", colors.black), ("M", colors.red), ("oro", colors.black)]
    text = c.beginText(50, height - 50)
    text.setFont("Helvetica-Bold", 14)
    for part, color in delmoro_text:
        text.setFillColor(color)
        text.textOut(part)
    c.drawText(text)

    # Add a red line
    c.setStrokeColor(colors.red)
    c.line(30, height - 60, width - 30, height - 60)

    # Add "FOR CLINICAL USE" text
    c.setFont("Helvetica-Bold", 12)
    c.setFillColor(colors.black)
    c.drawString(190, height - 107, "FOR CLINICAL USE")

    # Add DelMoro logo
    c.drawImage(delmorologo, width - 580, height - 132, width=140, height=70)

    # Add report date
    report_date_text = datetime.now().strftime("Report Date: %Y-%m-%d")
    c.setFont("Helvetica", 6)
    c.setFillColor(colors.black)
    c.drawRightString(width - 50, height - 50, report_date_text)

    # Draw patient information
    c.setFont("Times-Roman", 8)
    c.setFillColor(colors.black)

    # Draw the identifier
    identifier = metadata["Identifier"]
    c.drawString(width - 200, height - 80, f"Identifier: {identifier}")

    # Draw a horizontal line below the identifier
    c.setStrokeColor(colors.black)
    c.setLineWidth(0.5)
    c.line(width - 200, height - 85, width - 30, height - 85)

    # Draw patient info in two columns
    start_x = width - 200
    start_y = height - 100
    patient_info = {
        "Sample ID": metadata["SampleID"],
        "Sex": metadata["Sex"],
        "Date of Birth": metadata["Dob"],
        "Ethnicity": metadata["Ethnicity"],
        "Diagnosis": metadata["Diagnosis"]
    }
    info_items = list(patient_info.items())
    for i in range(0, len(info_items), 2):
        key1, value1 = info_items[i]
        c.drawString(start_x, start_y, f"{key1}: {value1}")
        if i + 1 < len(info_items):
            key2, value2 = info_items[i + 1]
            c.drawString(start_x + 100, start_y, f"{key2}: {value2}")
        start_y -= 15

    # Draw the footer
    footer_y = 40
    # Set font and colors
    c.setFont("Helvetica", 7)
    c.setFillColor(colors.HexColor('#808080'))  # Grey color for disclaimer

    # Disclaimer text (single line)
    disclaimerText = "Disclaimer: These findings should be interpreted by a clinical geneticist in the context of the patient's complete clinical presentation and family history."
    c.drawString(30, 55, disclaimerText)
    # Draw the horizontal line below the disclaimer
    c.setStrokeColor(colors.black)
    c.line(30,  50, width - 30,  50)

    # Page information (in black)
    c.setFillColor(colors.black)
    c.setFont("Helvetica", 8)
    c.drawString(30, 40,  f"Delmoro | Email: zemzemfiras@gmail.com | Page {c.getPageNumber()}")
    # Draw QR code at bottom right
    qr = qrcode.QRCode(version=1, box_size=6, border=2)
    qr.add_data("https://github.com/othmanResearch/DelMoro")
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="black", back_color="white")
    qr_img.save("delmoro_qr.png")
    c.drawImage("delmoro_qr.png", width - 80, 20, width=50, height=50)
    os.remove("delmoro_qr.png")

    # Add GitHub QR code if it exists
    if os.path.exists("github_qr.png"):
        c.drawImage("github_qr.png", width - 100, footer_y - 30, width=50, height=50)

##################################################################################


def extract_assembly_reference(vcFile):

    assembly_pattern = r'assembly=([^> ,]+)'
    try:
        # Handle both gzipped and uncompressed VCF files
        opener = gzip.open if vcFile.endswith('.gz') else open
        with opener(vcFile, 'rt') as vcf:
            for line in vcf:
                if line.startswith('##'):
                    match = re.search(assembly_pattern, line)
                    if match:
                        return match.group(1).strip('"')
                elif line.startswith('#'):
                    break
        return 'unknown'
    except Exception as e:
        return 'unknown'


##################################################################################
# COVERAGE REPORT
##################################################################################

THRESHOLDS = [1, 10, 20, 30, 50, 100]


def create_coverage_accumulator():
    return {
        "total_bases": 0,
        "depth_bases": 0.0,
        "threshold_bases": {threshold: 0 for threshold in THRESHOLDS},
        "depth_histogram": defaultdict(int),
    }


def add_coverage_depth(accumulator, length, depth):
    if length <= 0:
        return

    accumulator["total_bases"] += length
    accumulator["depth_bases"] += length * depth
    accumulator["depth_histogram"][depth] += length

    for threshold in THRESHOLDS:
        if depth >= threshold:
            accumulator["threshold_bases"][threshold] += length


def read_target_bed(filename):
    
    #Read target BED and merge overlapping/adjacent intervals.
    #Expected:
    #    chromosome start end
    #Additional BED columns are ignored.

    targets = defaultdict(list)

    if filename is None:
        return None

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

            # Common BED header
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
                    f"Invalid target coordinates on line {line_number}: "
                    f"{line}"
                ) from e

            if start < 0:
                raise ValueError(
                    f"Negative target coordinate on line {line_number}: "
                    f"{line}"
                )

            if end <= start:
                raise ValueError(
                    f"Invalid target interval on line {line_number}: "
                    f"{line}"
                )

            targets[chrom].append((start, end))
    # --------------------------------------------------------------
    # Sort and merge overlapping/adjacent intervals
    # --------------------------------------------------------------

    merged_targets = {}

    for chrom, intervals in targets.items():

        intervals.sort()

        merged = []

        for start, end in intervals:

            if merged and start <= merged[-1][1]:

                merged[-1] = (
                    merged[-1][0],
                    max(merged[-1][1], end)
                )

            else:

                merged.append((start, end))

        merged_targets[chrom] = merged

    return merged_targets
    return merged_targets


def calculate_target_territory(targets):

    if targets is None:
        return 0

    total = 0

    for intervals in targets.values():

        for start, end in intervals:
            total += end - start

    return total


def finalize_coverage_statistics(accumulator):

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

    # --------------------------------------------------------------
    # Mean
    # --------------------------------------------------------------

    mean_depth = (
        accumulator["depth_bases"] / total_bases
    )

    # --------------------------------------------------------------
    # Weighted median
    # --------------------------------------------------------------

    midpoint = total_bases / 2

    cumulative = 0

    median_depth = 0.0

    for depth in sorted(accumulator["depth_histogram"]):

        cumulative += accumulator["depth_histogram"][depth]

        if cumulative >= midpoint:

            median_depth = depth
            break

    # --------------------------------------------------------------
    # Threshold percentages
    # --------------------------------------------------------------

    pct = {}

    for threshold in THRESHOLDS:

        covered = accumulator["threshold_bases"][threshold]

        pct[threshold] = (
            covered / total_bases * 100
        )

    return {

        "total_bases": total_bases,

        "mean_depth": mean_depth,

        "median_depth": median_depth,

        "pct_0x": max(
            0.0,
            100.0 - pct[1]
        ),

        "pct_lt10x": max(
            0.0,
            100.0 - pct[10]
        ),

        "pct_lt20x": max(
            0.0,
            100.0 - pct[20]
        ),

        "pct_1x": pct[1],

        "pct_10x": pct[10],

        "pct_20x": pct[20],

        "pct_30x": pct[30],

        "pct_50x": pct[50],

        "pct_100x": pct[100],
    }

def process_coverage_file(coverage_file, targets=None):

    overall = create_coverage_accumulator()

    chromosome_data = defaultdict(
        create_coverage_accumulator
    )

    target_index = defaultdict(int)

    with open(
        coverage_file,
        "r",
        encoding="utf-8"
    ) as fh:

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
                fields[0].lower() in {
                    "chrom",
                    "chromosome"
                }
                and fields[1].lower() == "start"
                and fields[2].lower() == "end"
                and fields[3].lower() in {
                    "coverage",
                    "depth"
                }
            ):
                continue

            chrom = fields[0]

            try:

                start = int(fields[1])
                end = int(fields[2])
                depth = float(fields[3])

            except ValueError as e:

                raise ValueError(
                    f"Invalid coverage values on line "
                    f"{line_number}: {line}"
                ) from e

            if start < 0:

                raise ValueError(
                    f"Negative coverage start on line "
                    f"{line_number}: {line}"
                )

            if end <= start:
                continue

            if depth < 0:

                raise ValueError(
                    f"Negative coverage on line "
                    f"{line_number}: {depth}"
                )

            # ======================================================
            # NO TARGET BED
            # ======================================================

            if targets is None:

                length = end - start

                add_coverage_depth(
                    overall,
                    length,
                    depth
                )

                add_coverage_depth(
                    chromosome_data[chrom],
                    length,
                    depth
                )

                continue

            # ======================================================
            # TARGET BED MODE
            # ======================================================

            if chrom not in targets:
                continue

            chrom_targets = targets[chrom]

            i = target_index[chrom]

            # Skip target intervals completely before
            # the current coverage interval.
            while (
                i < len(chrom_targets)
                and chrom_targets[i][1] <= start
            ):
                i += 1

            target_index[chrom] = i

            # ------------------------------------------------------
            # Intersect coverage interval with target intervals
            # ------------------------------------------------------

            while (
                i < len(chrom_targets)
                and chrom_targets[i][0] < end
            ):

                target_start, target_end = chrom_targets[i]

                overlap_start = max(
                    start,
                    target_start
                )

                overlap_end = min(
                    end,
                    target_end
                )

                if overlap_end > overlap_start:

                    length = (
                        overlap_end - overlap_start
                    )

                    add_coverage_depth(
                        overall,
                        length,
                        depth
                    )

                    add_coverage_depth(
                        chromosome_data[chrom],
                        length,
                        depth
                    )

                if target_end <= end:

                    i += 1
                    target_index[chrom] = i

                else:

                    break

    return overall, chromosome_data
##################################################################################
def draw_coverage_report(
    c,
    width,
    height,
    bam_bed_file,
    target_bed_file
):

    # ==============================================================
    # Page layout
    # ==============================================================

    left = 30
    right = 30
    top = height - 155
    bottom = 65

    body_width = width - left - right

    # ==============================================================
    # Read target BED
    # ==============================================================

    target_mode = (
        target_bed_file is not None
        and os.path.basename(str(target_bed_file)) != "NO_FILE"
    )

    if target_mode:
        targets = read_target_bed(target_bed_file)
        target_territory = calculate_target_territory(targets)
    else:
        targets = None
        target_territory = None

    # ==============================================================
    # Process coverage
    # ==============================================================

    overall_accumulator, chromosome_accumulators = (
        process_coverage_file(
            bam_bed_file,
            targets
        )
    )

    overall = finalize_coverage_statistics(
        overall_accumulator
    )

    chromosome_stats = {}

    for chrom, accumulator in chromosome_accumulators.items():
        chromosome_stats[chrom] = finalize_coverage_statistics(
            accumulator
        )

    # ==============================================================
    # TITLE
    # ==============================================================

    c.setFillColor(colors.HexColor("#2c3e50"))
    c.setFont("Helvetica-Bold", 16)

    c.drawString(
        left,
        top,
        "Coverage Report"
    )

    top -= 20

    c.setFillColor(colors.HexColor("#666666"))
    c.setFont("Helvetica", 8)

    description = (
        "Coverage restricted to target/capture BED"
        if target_mode
        else
        "All bases represented in coverage BED"
    )

    c.drawString(
        left,
        top,
        description
    )

    top -= 16

    # ==============================================================
    # COVERAGE INFORMATION TABLE
    # ==============================================================

    info_data = [
        [
            Paragraph("<b>Coverage file</b>", coverage_styles["Normal"]),
            Paragraph(
str(os.path.basename(str(bam_bed_file))),
coverage_styles["Normal"]
            )
        ],

        [
            Paragraph("<b>Target BED</b>", coverage_styles["Normal"]),
            Paragraph(
str(os.path.basename(str(target_bed_file)))
if target_mode else
"Not supplied",
coverage_styles["Normal"]
            )
        ],

        [
            Paragraph("<b>Analysis</b>", coverage_styles["Normal"]),
            Paragraph(
description,
coverage_styles["Normal"]
            )
        ],

        [
            Paragraph("<b>Bases evaluated</b>", coverage_styles["Normal"]),
            Paragraph(
f"{overall['total_bases']:,} bp",
coverage_styles["Normal"]
            )
        ],
    ]

    if target_mode:
        info_data.append(
            [
Paragraph(
    "<b>Target territory</b>",
    coverage_styles["Normal"]
),
Paragraph(
    f"{target_territory:,} bp",
    coverage_styles["Normal"]
)
            ]
        )

    info_table = Table(
        info_data,
        colWidths=[
            100,
            body_width - 100
        ]
    )

    info_table.setStyle(
        TableStyle([
            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#f9f9f9") ),
            ("LINEBEFORE", (0, 0), (0, -1), 4, colors.HexColor("#4CAF50") ),
            ("GRID", (0, 0), (-1, -1), 0.3, colors.HexColor("#dddddd") ),
            ("VALIGN", (0, 0), (-1, -1), "TOP" ),
            ( "LEFTPADDING", (0, 0), (-1, -1), 7 ),
            ( "RIGHTPADDING", (0, 0), (-1, -1), 7 ),
            ( "TOPPADDING", (0, 0), (-1, -1), 4 ),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 4 ),
        ])
    )

    iw, ih = info_table.wrap(
        body_width,
        150
    )

    info_table.drawOn(
        c,
        left,
        top - ih
    )

    top -= ih + 12

    # ==============================================================
    # OVERALL + WES SUMMARY TABLES
    # ==============================================================
    #
    # IMPORTANT:
    # Use explicit X positions and widths that add up exactly
    # to the available page width.
    #
    # ==============================================================
    
    gap = 15

    overall_width = 190
    summary_x = left + overall_width + gap
    summary_width = body_width - overall_width - gap

    # --------------------------------------------------------------
    # Overall coverage
    # --------------------------------------------------------------

    c.setFillColor(colors.HexColor("#34495e"))
    c.setFont("Helvetica-Bold", 11)

    c.drawString(
        left,
        top,
        "Overall Coverage"
    )

    overall_data = [
        ["Metric", "Value"],
        ["Bases evaluated", f"{overall['total_bases']:,}" ],
        ["Mean Coverage", f"{overall['mean_depth']:.2f}×" ],
        ["Median Coverage", f"{overall['median_depth']:.2f}×"],
        ["0× Coverage", f"{overall['pct_0x']:.2f}%" ],
        ["<10× Coverage", f"{overall['pct_lt10x']:.2f}%"],
        ["<20× Coverage", f"{overall['pct_lt20x']:.2f}%"],
        ["≥1× Coverage", f"{overall['pct_1x']:.2f}%"],
        ["≥10× Coverage", f"{overall['pct_10x']:.2f}%"],
        ["≥20× Coverage", f"{overall['pct_20x']:.2f}%"],
        ["≥30× Coverage",f"{overall['pct_30x']:.2f}%"],
        ["≥50× Coverage",f"{overall['pct_50x']:.2f}%"],
        ["≥100× Coverage",f"{overall['pct_100x']:.2f}%"],
    ]

    overall_table = Table(
        overall_data,
        colWidths=[
            overall_width - 65,
            65
        ]
    )

    overall_table.setStyle(
        TableStyle([

            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#4CAF50") ),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white ),
            ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#cccccc") ),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#f2f2f2") ]),
            ("ALIGN", (1, 1), (1, -1), "RIGHT"),
            ("VALIGN", (0, 0), (-1, -1), "MIDDLE"),
            ("FONTSIZE", (0, 0), (-1, -1), 7 ),
            ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ("RIGHTPADDING", (0, 0), (-1, -1), 5 ),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
            ])
        )

    ow, oh = overall_table.wrap(overall_width, 300 )
    overall_table.drawOn( c, left, top - 14 - oh)

    # --------------------------------------------------------------
    # WES summary
    # --------------------------------------------------------------

    c.setFillColor(colors.HexColor("#34495e"))
    c.setFont("Helvetica-Bold", 11)

    c.drawString(
        summary_x,
        top,
        "WES Coverage Summary"
    )

    summary_data = [
        ["Metric", "Value"],
        ["Mean depth", f"{overall['mean_depth']:.2f}×"],
        ["Median depth", f"{overall['median_depth']:.2f}×"],
        ["≥20×",f"{overall['pct_20x']:.2f}%" ],
        ["≥30×",f"{overall['pct_30x']:.2f}%"],
        ["≥50×",f"{overall['pct_50x']:.2f}%"],
        ["≥100×",f"{overall['pct_100x']:.2f}%" ],
        ["0×",f"{overall['pct_0x']:.2f}%"],
        ["<10×",f"{overall['pct_lt10x']:.2f}%"],
    ]

    summary_table = Table(
        summary_data,
        colWidths=[
            summary_width - 65,
            65
        ]
    )

    summary_table.setStyle(
        TableStyle([

            ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2e7d32")),
            ("TEXTCOLOR", (0, 0), (-1, 0), colors.white ),
            ("BACKGROUND", (0, 1), (-1, -1), colors.HexColor("#e8f5e9")),
            ("GRID", (0, 0), (-1, -1), 0.4, colors.HexColor("#bdbdbd")),
            ("ALIGN", (1, 1), (1, -1), "RIGHT"),
            ( "VALIGN",(0, 0),(-1, -1), "MIDDLE"),
            ("FONTSIZE", (0, 0), (-1, -1), 7 ),
            ("LEFTPADDING", (0, 0), (-1, -1), 5),
            ("RIGHTPADDING", (0, 0),(-1, -1), 5),
            ("TOPPADDING", (0, 0), (-1, -1), 3),
            ("BOTTOMPADDING", (0, 0), (-1, -1),3),
        ])
    )

    sw, sh = summary_table.wrap(summary_width, 250 )
    summary_table.drawOn(c, summary_x, top - 14 - sh )

    # ==============================================================
    # PER-CHROMOSOME SECTION
    # ==============================================================

    chromosome_y = top - 14 - max(oh, sh) - 18

    c.setFillColor(colors.HexColor("#34495e"))
    c.setFont("Helvetica-Bold", 11)

    c.drawString(
        left,
        chromosome_y,
        "Per-Chromosome Coverage"
    )

    chromosome_y -= 14

    c.setFillColor(colors.HexColor("#666666"))
    c.setFont("Helvetica", 6.5)

    explanation = (
        "Only target BED bases are included in the statistics."
        if target_mode
        else
        "Statistics represent intervals contained in the supplied coverage BED."
    )

    c.drawString(
        left,
        chromosome_y,
        explanation
    )

    chromosome_y -= 8

    # ==============================================================
    # Chromosome table
    # ==============================================================

    chromosome_data = [[
        "Chromosome",
        "Bases",
        "Mean",
        "Median",
        "0×",
        "≥10×",
        "≥20×",
        "≥30×",
        "≥50×",
        "≥100×"
    ]]

    for chrom in sorted(chromosome_stats):

        stats = chromosome_stats[chrom]

        chromosome_data.append([
            str(chrom),
            f"{stats['total_bases']:,}",
            f"{stats['mean_depth']:.2f}×",
            f"{stats['median_depth']:.2f}×",
            f"{stats['pct_0x']:.2f}%",
            f"{stats['pct_10x']:.2f}%",
            f"{stats['pct_20x']:.2f}%",
            f"{stats['pct_30x']:.2f}%",
            f"{stats['pct_50x']:.2f}%",
            f"{stats['pct_100x']:.2f}%"
        ])

    # --------------------------------------------------------------
    # FIXED WIDTH
    #
    # Total = 526 pt, safely inside 552 pt body width.
    # --------------------------------------------------------------

    chromosome_col_widths = [
        65,
        65,
        52,
        52,
        48,
        48,
        48,
        48,
        48,
        52
    ]

    chromosome_table = Table(
        chromosome_data,
        colWidths=chromosome_col_widths,
        repeatRows=1
    )

    chromosome_table.setStyle(
        TableStyle([

            (
"BACKGROUND",
(0, 0),
(-1, 0),
colors.HexColor("#4CAF50")
            ),

            (
"TEXTCOLOR",
(0, 0),
(-1, 0),
colors.white
            ),

            (
"GRID",
(0, 0),
(-1, -1),
0.35,
colors.HexColor("#cccccc")
            ),

            (
"ROWBACKGROUNDS",
(0, 1),
(-1, -1),
[
    colors.white,
    colors.HexColor("#f2f2f2")
]
            ),

            (
"ALIGN",
(1, 1),
(-1, -1),
"RIGHT"
            ),

            (
"VALIGN",
(0, 0),
(-1, -1),
"MIDDLE"
            ),

            (
"FONTSIZE",
(0, 0),
(-1, -1),
6.2
            ),

            (
"LEFTPADDING",
(0, 0),
(-1, -1),
2
            ),

            (
"RIGHTPADDING",
(0, 0),
(-1, -1),
2
            ),

            (
"TOPPADDING",
(0, 0),
(-1, -1),
2.5
            ),

            (
"BOTTOMPADDING",
(0, 0),
(-1, -1),
2.5
            ),
        ])
    )

    cw, ch = chromosome_table.wrap(
        body_width,
        height
    )

    # ==============================================================
    # If chromosome table does not fit:
    # split automatically across pages
    # ==============================================================

    available_height = chromosome_y - bottom

    if ch <= available_height:

        chromosome_table.drawOn(
            c,
            left,
            chromosome_y - ch
        )

        chromosome_bottom = chromosome_y - ch

    else:

        # Split table into chunks that fit on the current page
        remaining_table = chromosome_table
        current_y = chromosome_y

        while remaining_table:

            available_height = current_y - bottom

            table_parts = remaining_table.split(
                body_width,
                available_height
            )

            if not table_parts:
                break

            current_part = table_parts[0]

            part_w, part_h = current_part.wrap(
                body_width,
                available_height
            )

            current_part.drawOn(
                c,
                left,
                current_y - part_h
            )

            remaining_table = (
                table_parts[1]
                if len(table_parts) > 1
                else None
            )

            if remaining_table:

                c.showPage()

                draw_header_to_footer(
                    c,
                    width,
                    height,
                    metadata,
                    delmorologo
                )

                current_y = height - 155

                c.setFillColor(
                    colors.HexColor("#34495e")
                )

                c.setFont(
                    "Helvetica-Bold",
                    11
                )

                c.drawString(
                    left,
                    current_y,
                    "Per-Chromosome Coverage (continued)"
                )

                current_y -= 18

        chromosome_bottom = bottom
        
    # ==============================================================
    # INTERPRETATION BOX
    # ==============================================================

    warning_text = (
        "<b>Interpretation:</b> "
        "For WES, target-restricted coverage is preferred when "
        "the capture/target BED is available. "
        "If no target BED is supplied, this report describes "
        "the bases represented by the supplied coverage file "
        "and should not be interpreted as a formal "
        "capture-target coverage metric."
    )

    warning_table = Table(
        [[
            Paragraph(
              warning_text,
              coverage_styles["Normal"]
            )
        ]],
        colWidths=[
            body_width
        ]
    )

    warning_table.setStyle(
        TableStyle([

            ("BACKGROUND", (0, 0), (-1, -1), colors.HexColor("#fff3e0") ),
            ("LINEBEFORE", (0, 0), (0, -1),4, colors.HexColor("#ef6c00") ),
            ("BOX", (0, 0), (-1, -1), 0.5, colors.HexColor("#ef6c00") ),
            ("LEFTPADDING", (0, 0), (-1, -1), 8),
            ("RIGHTPADDING", (0, 0), (-1, -1), 8),
            ("TOPPADDING", (0, 0), (-1, -1), 5),
            ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
        ])
    )

    ww, wh = warning_table.wrap( body_width, 100 )

    warning_y = chromosome_bottom - 12

    # Only draw warning box when it fits.
    if warning_y - wh >= bottom:
        warning_table.drawOn( c, left, warning_y - wh )
        

##################################################################################
# Draw header, patient info, and footer on the first page
draw_header_to_footer(c, width, height, metadata, delmorologo)

def order_info(c, width, height, metaYaml):
    xpos_left = 50
    xpos_right = xpos_left + 280
    ypos = height - 170
    line_height = 18

    # ----------------- Physician Info -----------------
    c.setFont("Helvetica-Bold", 9)
    c.drawString(xpos_left, ypos, "Physician Info:")
    c.setFont("Helvetica", 8)

    physician_data = [
        ("Name", metaYaml.get('physician', {}).get('name', 'N/A')),
        ("Specialty", metaYaml.get('physician', {}).get('specialty', 'N/A')),
        ("Email", metaYaml.get('physician', {}).get('contact', {}).get('email', 'N/A')),
        ("Phone", metaYaml.get('physician', {}).get('contact', {}).get('phone', 'N/A')),
        ("Affiliation", metaYaml.get('physician', {}).get('affiliation', 'N/A')),
    ]

    # Draw first row (same line as header)
    c.drawString(xpos_left + 100, ypos, f"{physician_data[0][0]}: {physician_data[0][1]}")
    if len(physician_data) > 1:
        c.drawString(xpos_right, ypos, f"{physician_data[1][0]}: {physician_data[1][1]}")
    ypos -= line_height

    # Draw remaining physician data
    for i in range(2, len(physician_data), 2):
        key1, val1 = physician_data[i]
        c.drawString(xpos_left + 100, ypos, f"{key1}: {val1}")
        if i + 1 < len(physician_data):
            key2, val2 = physician_data[i + 1]
            c.drawString(xpos_right, ypos, f"{key2}: {val2}")
        ypos -= line_height

    # ----------------- Institution Info -----------------
    c.setFont("Helvetica-Bold", 9)
    c.drawString(xpos_left, ypos, "Institution Info:")
    c.setFont("Helvetica", 8)

    address = metaYaml.get('institution', {}).get('address', {})
    full_address = ', '.join(filter(None, [
        address.get('street', ''),
        address.get('city', ''),
        address.get('state', ''),
        str(address.get('zip', '')) if address.get('zip') else '',
        address.get('country', '')
    ]))

    institution_data = [
        ("Name", metaYaml.get('institution', {}).get('name', 'N/A')),
        ("Department", metaYaml.get('institution', {}).get('department', 'N/A')),
        ("Accreditation", metaYaml.get('institution', {}).get('accreditation', 'N/A')),
        ("Address", full_address),
    ]

    # Draw first row aligned with header
    c.drawString(xpos_left + 100, ypos, f"{institution_data[0][0]}: {institution_data[0][1]}")
    if len(institution_data) > 1:
        c.drawString(xpos_right, ypos, f"{institution_data[1][0]}: {institution_data[1][1]}")
    ypos -= line_height

    # Draw remaining institution data
    for i in range(2, len(institution_data), 2):
        key1, val1 = institution_data[i]
        c.drawString(xpos_left + 100, ypos, f"{key1}: {val1}")
        if i + 1 < len(institution_data):
            key2, val2 = institution_data[i + 1]
            c.drawString(xpos_right, ypos, f"{key2}: {val2}")
        ypos -= line_height

    # ----------------- HPO Terms -----------------
    c.setFont("Helvetica-Bold", 9)
    c.drawString(xpos_left, ypos, "HPO Terms:")
    c.setFont("Helvetica", 8)

    hpo_terms = metaYaml.get('hpo_terms', [])
    hpo_ids = ', '.join([str(term.get('id', '')) for term in hpo_terms]) if hpo_terms else 'None provided'
    hpo_terms_text = ', '.join([term.get('term', '') for term in hpo_terms]) if hpo_terms else 'None provided'

    # Draw first row aligned with header
    c.drawString(xpos_left + 100, ypos, f"IDs:   {hpo_ids}")
    ypos -= line_height
    c.drawString(xpos_left + 100, ypos, f"Terms: {hpo_terms_text}")
    ypos -= line_height

    # ----------------- Vertical Line -----------------
    c.setStrokeColor(colors.red)
    c.line(125, height - 160, 125, 60)

    c.setStrokeColor(colors.red)
    c.line(150, ypos - 10, xpos_right + 250, ypos - 10)  # Adjusted to match original line length
    ypos -= 30
    
    # Reference Genome
    assembly_version = extract_assembly_reference(vcFile)
    c.setFont("Helvetica-Bold", 9)
    c.drawString(xpos_left, ypos, "Reference:")
    c.setFont("Helvetica", 8)
    c.drawString(xpos_left + 100, ypos, assembly_version)  # No f-string needed now
    ypos -= line_height

order_info(c, width, height, metaYaml)

##################################################################################

c.showPage()
draw_header_to_footer( c, width, height, metadata, delmorologo )
draw_coverage_report( c, width, height, bamBedFile, bedTargetFile )
##################################################################################

# Function to add a plot to the PDF
def add_plot_to_pdf(plot_file, c, width, height, plot_index):
    # Define margins (top, bottom, left, right)
    margin_left = 30
    margin_right = 30
    margin_top = 150
    margin_bottom = 60

    # Define grid structure
    plots_per_row = 3
    num_rows_per_page = 4
    plots_per_page = plots_per_row * num_rows_per_page

    # Calculate plot dimensions
    plot_width = ( width - margin_left - margin_right) / plots_per_row
    plot_height = ( height - margin_top - margin_bottom ) / num_rows_per_page

    # Compute the row and column
    page_index = plot_index // plots_per_page
    index_in_page = plot_index % plots_per_page
    row = index_in_page // plots_per_row
    col = index_in_page % plots_per_row

    # If this is the first plot on a new page
    if index_in_page == 0 and plot_index > 0:
        c.showPage()
        draw_header_to_footer(c, width, height, metadata, delmorologo )

    # --------------------------------------------------------------
    # Add text before the first plot
    # --------------------------------------------------------------

    if plot_index == 0:
        c.setFillColor(colors.HexColor("#2c3e50"))
        c.setFont("Helvetica-Bold",14)
        c.drawString(margin_left,height - 145,"Variant scope: Whole VCF")

    # --------------------------------------------------------------
    # Compute plot position
    # --------------------------------------------------------------

    x = ( margin_left + col * plot_width )
    y = ( height - margin_top - (row + 1) * plot_height )

    # Draw the plot
    c.drawImage( plot_file, x, y, width=plot_width, height=plot_height, preserveAspectRatio=True )

##################################################################################

# Draw header, patient info, and footer on the first page
#draw_header_to_footer(c, width, height, metadata, delmorologo)

# Save the current page
c.showPage()
draw_header_to_footer(c, width, height, metadata, delmorologo)


##################################################################################

# Function to create the variant type distribution plot
def create_variant_type_plot(df, sample_plot_dir, vcf_basename):
    # Count variant types
    variant_counts = df['variant_type'].value_counts()

    # Create a bar plot with count labels above the bars
    plt.figure(figsize=(10, 8))
    bars = plt.bar(variant_counts.index, variant_counts.values, color=['blue', 'green', 'orange'])
    for bar in bars:
        yval = bar.get_height()
        plt.text(bar.get_x() + bar.get_width() / 2, yval + 0.1, str(int(yval)), ha='center', va='bottom')
    plt.title(f'Distribution of Variant Types for {vcf_basename}')
    plt.xlabel('Variant Type')
    plt.ylabel('Count')

    # Save the plot
    plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f1_VarType.png")
    plt.savefig(plot_file)
    plt.close()

    return plot_file

##################################################################################

# Function to create the INDEL size distribution plot
def create_indel_size_plot(df, sample_plot_dir, vcf_basename):
    ref = df['REF']
    alts = df['ALT']
    indel_sizes = []

    # Calculate INDEL sizes based on REF and ALT lengths
    for r, a in zip(ref, alts):
        if isinstance(a, list):
            max_alt_len = max(len(alt) for alt in a if alt)
        else:
            max_alt_len = len(a)

        if len(r) != max_alt_len:
            indel_sizes.append(abs(len(r) - max_alt_len))

    if indel_sizes:
        # Plotting INDEL size distribution
        plt.figure(figsize=(10, 8))
        sns.histplot(indel_sizes, bins=30, kde=True, color='blue')
        plt.title(f'Size Distribution of INDELs for {vcf_basename}')
        plt.xlabel('INDEL Size')
        plt.ylabel('Count')

        # Save plot with the base filename included
        plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f2_indelSize.png")
        plt.savefig(plot_file)
        plt.close()

        return plot_file
    return None

##################################################################################

# Function to create the depth per position plot
def create_depth_per_position_plot(df, sample_plot_dir, vcf_basename):
    # Extract DP values
    df["DP"] = df["INFO"].apply(lambda info: next((int(field.split("=")[1]) for field in info.split(";") if field.startswith("DP=")), None))

    # Drop rows where DP is missing
    df = df.dropna(subset=["DP"])

    # Clean positions (ensure they're unique and sorted)
    pos_clean = sorted(df["POS"].unique())

    # Plot Depth per Position with improvements
    plt.figure(figsize=(10, 8))
    sns.barplot(x=df["POS"], y=df["DP"], color='orange')

    # Title and labels with better clarity
    plt.title(f'Depth per Position for {vcf_basename}')
    plt.xlabel('Position')
    plt.ylabel('Depth (DP)')

    # Rotate x-axis labels to avoid overlap
    plt.xticks(rotation=45, ha="right", fontstyle='italic')

    # Reduce the number of ticks to avoid crowding
    if len(pos_clean) > 20:  # Show only 20 ticks if too many positions
        tick_indices = np.linspace(0, len(pos_clean) - 1, 20, dtype=int)
        plt.xticks(tick_indices, [pos_clean[i] for i in tick_indices])

    # Adjust plot for large number of positions
    plt.tight_layout()

    # Save the plot
    plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f3_DpPerPos.png")
    plt.savefig(plot_file)
    plt.close()

    return plot_file

##################################################################################

# Function to create the quality distribution plot
def create_quality_distribution_plot(df, sample_plot_dir, vcf_basename):
    # Drop rows where QUAL is missing
    df = df.dropna(subset=['QUAL'])

    # Plotting Quality distribution
    plt.figure(figsize=(10, 8))
    sns.scatterplot(df['QUAL'])
    plt.title(f'Quality Distribution for {vcf_basename}')
    plt.xlabel('Quality (QUAL)')
    plt.ylabel('Count')

    # Save plot with the base filename included
    plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f4.png")
    plt.savefig(plot_file)
    plt.close()

    return plot_file

##################################################################################

# Function to create the transitions vs transversions plot

def create_transitions_transversions_plot(df, sample_plot_dir, vcf_basename):
    df = df.dropna(subset=['REF', 'ALT']).copy()

    df['REF'] = df['REF'].astype(str).str.upper()
    df['ALT'] = df['ALT'].astype(str).str.upper()

    # Keep only biallelic SNPs
    df = df[
        (df['REF'].str.len() == 1) &
        (df['ALT'].str.len() == 1) &
        (df['REF'].isin(['A', 'C', 'G', 'T'])) &
        (df['ALT'].isin(['A', 'C', 'G', 'T']))
    ].copy()

    transitions = {'AG', 'GA', 'CT', 'TC'}

    df['mutation_type'] = (df['REF'] + df['ALT']).apply(
        lambda x: 'Transition' if x in transitions else 'Transversion'
    )

    transition_count = (df['mutation_type'] == 'Transition').sum()
    transversion_count = (df['mutation_type'] == 'Transversion').sum()

    titv = (
        transition_count / transversion_count
        if transversion_count > 0
        else float('inf')
    )

    categories = ['Transition', 'Transversion']
    counts = [transition_count, transversion_count]

    fig, ax = plt.subplots(figsize=(10, 8))
    
    bars = ax.bar(categories, counts, color=['green', 'red'] )

    max_count = max(counts) if counts else 0

    for bar, count in zip(bars, counts):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            count + max_count * 0.02 if max_count > 0 else 0.1,
            f'{count:,}',
            ha='center',
            va='bottom'
        )

    ax.set_title(f'Transitions vs Transversions for {vcf_basename}')
    ax.set_xlabel('Mutation Type')
    ax.set_ylabel('Count')

    titv_text = f'Ti/Tv = {titv:.2f}' if transversion_count > 0 else 'Ti/Tv = ∞'

    ax.text(0.5, 0.95, titv_text, transform=ax.transAxes, ha='center', va='top', fontsize=13, fontweight='bold')

    ax.set_ylim(0, max_count * 1.15 if max_count > 0 else 1)

    os.makedirs(sample_plot_dir, exist_ok=True)

    plot_file = os.path.join(sample_plot_dir,f'{vcf_basename}_f5_TiTv.png')

    fig.tight_layout()
    fig.savefig(plot_file, dpi=300, bbox_inches='tight')
    plt.close(fig)

    return plot_file


##################################################################################

# Function to create the specific mutations counts plot
def create_specific_mutations_plot(df, sample_plot_dir, vcf_basename):
    # Drop rows where ALT is missing
    df = df.dropna(subset=['ALT'])

    # Define mutation dictionary
    mutation_dict = {
        'A > T': 0, 'A > C': 0, 'A > G': 0,
        'G > A': 0, 'G > T': 0, 'G > C': 0,
        'C > A': 0, 'C > T': 0, 'C > G': 0,
        'T > A': 0, 'T > C': 0, 'T > G': 0
    }

    # Classify mutations
    df['mutation_type'] = df.apply(lambda row: f"{row['REF']} > {row['ALT']}", axis=1)
    mutation_counts = df['mutation_type'].value_counts()

    # Update mutation dictionary with counts
    for mutation in mutation_counts.index:
        if mutation in mutation_dict:
            mutation_dict[mutation] = mutation_counts[mutation]

    # Plot specific mutations counts
    plt.figure(figsize=(10, 8))
    plt.barh(list(mutation_dict.keys()), list(mutation_dict.values()), color='orange')

    # Add counts to the bars
    for i, value in enumerate(mutation_dict.values()):
        plt.text(value + 0.1, i, str(value), va='center')

    plt.title(f'Specific Mutations Counts for {vcf_basename}')
    plt.xlabel('Count')
    plt.ylabel('Mutation Type')

    # Save the plot
    plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f6_mutations_plot.png")
    plt.savefig(plot_file)
    plt.close()

    return plot_file


##################################################################################

# Function to create the average depth per chromosome plot
def create_depth_per_chromosome_plot(df, sample_plot_dir, vcf_basename):
    # Compute average depth per chromosome
    depth_per_chromosome = df.groupby("CHROM")["DP"].mean().sort_values(ascending=False)

    # Create the plot
    plt.figure(figsize=(10, 8))
    depth_per_chromosome.plot(kind='bar', color='teal')

    # Add value labels above bars
    for i, value in enumerate(depth_per_chromosome.values):
        plt.text(i, value + 0.1, f"{value:.1f}", ha='center', va='bottom', fontsize=10)

    # Set plot labels and title
    plt.title(f'Average Depth Per Chromosome for {vcf_basename}')
    plt.xlabel('Chromosome')
    plt.ylabel('Average Depth (DP)')
    plt.xticks(rotation=45)  # Rotate x-axis labels for better readability

    # Save the plot
    plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f7_depth_per_chromosome.png")
    plt.savefig(plot_file, bbox_inches="tight")
    plt.close()

    return plot_file

##################################################################################

def create_allele_balance_plot(df, sample_plot_dir, vcf_basename):

    # Extract AB from FORMAT/SAMPLE
    def extract_ab(row):
        format_fields = str(row['FORMAT']).split(':')
        sample_fields = str(row['SAMPLE']).split(':')

        format_dict = dict(zip(format_fields, sample_fields))

        try:
            return float(format_dict.get('AB', np.nan))
        except (ValueError, TypeError):
            return np.nan

    # Extract existing AB field
    ab_df = df.copy()
    ab_df['AB'] = ab_df.apply(extract_ab, axis=1)

    # Remove missing or invalid AB values
    ab_df = ab_df.dropna(subset=['AB'])
    ab_df = ab_df[
        (ab_df['AB'] >= 0) &
        (ab_df['AB'] <= 1)
    ]

    # Plot allele balance distribution
    plt.figure(figsize=(8, 6))

    plt.hist(
        ab_df['AB'],
        bins=20,
        edgecolor='black'
    )

    # Expected allele balance for a heterozygous variant
    plt.axvline(
        0.5,
        linestyle='--',
        linewidth=2,
        label='Expected heterozygous AB = 0.50'
    )

    plt.title(f'Allele Balance Distribution for {vcf_basename}')
    plt.xlabel('Allele Balance (AB)')
    plt.ylabel('Variant Count')
    plt.xlim(0, 1)
    plt.legend()
    plt.tight_layout()

    # Save plot
    # Save plot
    plot_file = os.path.join(sample_plot_dir,f"{vcf_basename}_f8_AB.png")

    plt.savefig(plot_file,dpi=300,bbox_inches='tight'
    )

    plt.close()

    return plot_file

##################################################################################
def create_genotype_representation_plot(df, sample_plot_dir, vcf_basename):

    # Extract GT from FORMAT/SAMPLE
    def extract_gt(row):
        format_fields = str(row['FORMAT']).split(':')
        sample_fields = str(row['SAMPLE']).split(':')

        format_dict = dict(zip(format_fields, sample_fields))

        return format_dict.get('GT', np.nan)

    # Extract genotype
    gt_df = df.copy()
    gt_df['GT'] = gt_df.apply(extract_gt, axis=1)

    # Remove missing genotypes
    gt_df = gt_df.dropna(subset=['GT'])
    gt_df = gt_df[gt_df['GT'].astype(str) != '.']

    # Classify genotypes
    def classify_genotype(gt):

        gt = str(gt).replace('|', '/')

        # Homozygous reference
        if gt == '0/0':
            return 'Homozygous Reference'

        # Heterozygous
        elif gt in ['0/1', '1/0']:
            return 'Heterozygous'

        # Homozygous alternate
        elif gt == '1/1':
            return 'Homozygous Alternate'

        # Other genotypes
        else:
            return 'Other'

    gt_df['Genotype_Class'] = gt_df['GT'].apply(classify_genotype)

    # Count each genotype class
    genotype_counts = (
        gt_df['Genotype_Class']
        .value_counts()
        .reindex(
            [
'Homozygous Reference',
'Heterozygous',
'Homozygous Alternate',
'Other'
            ],
            fill_value=0
        )
    )

    # Create the plot
    plt.figure(figsize=(10, 8))

    bars = plt.bar(
        genotype_counts.index,
        genotype_counts.values,
        color=[
            '#4C78A8',  # Homozygous Reference - blue
            '#F2CF5B',  # Heterozygous - yellow
            '#E45756',  # Homozygous Alternate - red
            '#72B7B2'   # Other - teal
        ],
        edgecolor='black'
    )
    # Add value labels above bars
    for bar, value in zip(bars, genotype_counts.values):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height(),
            f'{value}',
            ha='center',
            va='bottom',
            fontsize=10
        )

    # Plot labels and title
    plt.title(
        f'Genotype Representation for {vcf_basename}'
    )
    plt.xlabel('Genotype Class')
    plt.ylabel('Variant Count')

    plt.xticks(rotation=20)

    plt.tight_layout()

    # Save plot
    plot_file = os.path.join(
        sample_plot_dir,
        f"{vcf_basename}_f9_genotypeRepresentation.png"
    )

    plt.savefig(
        plot_file,
        dpi=300,
        bbox_inches='tight'
    )

    plt.close()

    return plot_file
##################################################################################
def create_pass_filtered_variants_plot(df, sample_plot_dir, vcf_basename):

    # Extract FILTER
    filter_df = df.copy()

    # Handle missing FILTER values
    filter_df['FILTER'] = filter_df['FILTER'].fillna('.').astype(str)

    # Classify variants
    def classify_filter(filter_value):

        # PASS variants
        if filter_value == 'PASS':
            return 'PASS'

        # Filtered variants
        else:
            return 'Filtered'

    filter_df['Filter_Class'] = filter_df['FILTER'].apply(
        classify_filter
    )

    # Count each filter class
    filter_counts = (
        filter_df['Filter_Class']
        .value_counts()
        .reindex(
            [
            'PASS',
            'Filtered'
            ],
            fill_value=0
        )
    )

    # Create the plot
    plt.figure(figsize=(8, 6))

    bars = plt.bar(
        filter_counts.index,
        filter_counts.values,
        color=['#2E8B57', '#D9534F'],
        edgecolor='black'
    )

    # Add value labels above bars
    for bar, value in zip(bars, filter_counts.values):
        plt.text(
            bar.get_x() + bar.get_width() / 2,
            bar.get_height(),
            f'{value}',
            ha='center',
            va='bottom',
            fontsize=10
        )

    # Plot labels and title
    plt.title(
        f'PASS vs Filtered Variants for {vcf_basename}'
    )
    plt.xlabel('Variant Filter Status')
    plt.ylabel('Variant Count')

    plt.tight_layout()

    # Save plot
    plot_file = os.path.join(
        sample_plot_dir,
        f"{vcf_basename}_f10_pass_vs_filtered.png"
    )

    plt.savefig(
        plot_file,
        dpi=300,
        bbox_inches='tight'
    )

    plt.close()

    return plot_file

##################################################################################
# Main script
# Load the extracted VCF TSV file with proper headers
df = pd.read_csv("${vcFile}", sep="\\t", header=None, names=[
    "CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT", "SAMPLE"
], comment='#')

# Ensure proper handling of missing or malformed data
df = df.dropna(subset=['ALT'])

# Determine variant type (SNP, MNV, or INDEL)
df['variant_type'] = df.apply(lambda row: 'SNP' if len(row['REF']) == 1 and len(row['ALT']) == 1 else
      'MNV' if len(row['REF']) > 1 and len(row['ALT']) > 1 and len(row['REF']) == len(row['ALT']) else
      'INDEL', axis=1)

vcf_basename = os.path.basename("${vcFile}").split(".")[0]



##################################################################################

# Create the variant type distribution plot

plot_file_f1 = create_variant_type_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f1, c, width, height, 0)

##################################################################################

# Create the INDEL size distribution plot
plot_file_f2 = create_indel_size_plot(df, sample_plot_dir, vcf_basename)
if plot_file_f2:
    add_plot_to_pdf(plot_file_f2, c, width, height, 1)


##################################################################################

# Create the depth per position plot
plot_file_f3 = create_depth_per_position_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f3, c, width, height, 2)


##################################################################################

# Create the quality distribution plot
plot_file_f4 = create_quality_distribution_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f4, c, width, height, 3)


##################################################################################

# Create the transitions vs transversions plot
plot_file_f5 = create_transitions_transversions_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f5, c, width, height, 4)


##################################################################################

# Create the specific mutations counts plot
plot_file_f6 = create_specific_mutations_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f6, c, width, height, 5)


##################################################################################

# Create the average depth per chromosome plot
plot_file_f7 = create_depth_per_chromosome_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f7, c, width, height, 6)
##################################################################################
# Create the Allele balance Plot
plot_file_f8 = create_allele_balance_plot(df, sample_plot_dir, vcf_basename)
add_plot_to_pdf(plot_file_f8, c, width, height, 7 )

##################################################################################
# Create genotype representation plot
plot_file_f9 = create_genotype_representation_plot(df,sample_plot_dir,vcf_basename)

add_plot_to_pdf(plot_file_f9,c,width, height, 8)

##################################################################################
# Create PASS vs filtered variants plot
plot_file_f10 = create_pass_filtered_variants_plot(df, sample_plot_dir,vcf_basename)
add_plot_to_pdf(plot_file_f10, c, width, height, 9)

##################################################################################
# Below a test of plots to be deleted later      #
##################################################################################
# Create the average depth per chromosome plot
# plot_file_f7 = create_depth_per_chromosome_plot(df, sample_plot_dir, vcf_basename)
# add_plot_to_pdf(plot_file_f7, c, width, height, 7)
##################################################################################

# Save the PDF
c.save()
    """
}

