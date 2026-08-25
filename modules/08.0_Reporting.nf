// Module files for DelMoro pipeline

// Reporting Module with reportlab

process GenerateReports {
    tag "GeNERATE PDF REPORTS "
    publishDir "${params.outdir}/Reporting/", mode: 'copy'

    conda "reportlab=4.4.1 matplotlib=3.9.1 seaborn=0.13.2 pandas=2.3.1 numpy=1.26.4 qrcode=8.2"
    container "${workflow.containerEngine == 'singularity'
        ? "docker://firaszemzem/pyreportlab-toolkit:1.0"
        : "firaszemzem/pyreportlab-toolkit:1.0"}"

    input:
    tuple val(metadata), path(vcFile), path(delmorologo), val(metaYaml)

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
from reportlab.platypus import Table, TableStyle
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

   assembly_pattern = r'assembly=([^>\s,]+)'
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

##################################################################################
# Function to add a plot to the PDF
def add_plot_to_pdf(plot_file, c, width, height, plot_index):
    # Define margins (top, bottom, left, right)
    margin_left = 30
    margin_right = 30
    margin_top = 150  # Reduced to fit more plots
    margin_bottom = 60  # Reduced to fit more plots

    # Define grid structure
    plots_per_row = 3
    num_rows_per_page = 4  # Ensures 4 rows fit per page
    plots_per_page = plots_per_row * num_rows_per_page  # 12 plots per page

    # Calculate plot dimensions
    plot_width = (width - margin_left - margin_right) / plots_per_row
    plot_height = (height - margin_top - margin_bottom) / num_rows_per_page  # Ensures 5 rows fit

    # Compute the row and column for the current plot
    page_index = plot_index // plots_per_page  # Determine current page number
    index_in_page = plot_index % plots_per_page  # Position within the current page
    row = index_in_page // plots_per_row  # Row within page (0-4)
    col = index_in_page % plots_per_row  # Column (0-2)

    # Compute position on the page
    x = margin_left + col * plot_width
    y = height - margin_top - (row + 1) * plot_height  # Row-wise positioning

    # If this is the first plot on a new page (not the first page), create a new page
    if index_in_page == 0 and plot_index > 0:
        c.showPage()  # Start a new page
        draw_header_to_footer(c, width, height, metadata, delmorologo)  # Add header/footer

    # Draw the plot image
    c.drawImage(plot_file, x, y, width=plot_width, height=plot_height, preserveAspectRatio=True)

##################################################################################

# Draw header, patient info, and footer on the first page
draw_header_to_footer(c, width, height, metadata, delmorologo)

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
    # Drop rows where REF or ALT is missing
    df = df.dropna(subset=['REF', 'ALT'])

    # Determine mutation type (transition or transversion)
    df['mutation_type'] = df.apply(lambda row: 'Transition' if row['REF'] + row['ALT'] in {'AG', 'GA', 'CT', 'TC'} else 'Transversion', axis=1)

    # Count mutation types
    mutation_counts = df['mutation_type'].value_counts()

    # Plot transitions vs transversions
    plt.figure(figsize=(10, 8))
    bars = plt.bar(mutation_counts.index, mutation_counts.values, color=['green', 'red'])

    # Add counts above bars
    for i, value in enumerate(mutation_counts.values):
        plt.text(i, value + 0.1, str(value), ha='center', va='bottom')

    plt.title(f'Transitions vs Transversions for {vcf_basename}')
    plt.xlabel('Mutation Type')
    plt.ylabel('Count')

    # Save the plot
    plot_file = os.path.join(sample_plot_dir, f"{vcf_basename}_f5_TiTv.png")
    plt.savefig(plot_file)
    plt.close()

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
#                 Below a test of plots to be deleted later                      #
##################################################################################
# Create the average depth per chromosome plot
# plot_file_f7 = create_depth_per_chromosome_plot(df, sample_plot_dir, vcf_basename)
# add_plot_to_pdf(plot_file_f7, c, width, height, 7)
##################################################################################

# Save the PDF
c.save()
    """
}

