// Generate CSVs in separate processes

process WriteTrimmingCSV {
    tag "PREPARE CSVs FOR Trimming"
    publishDir "./CSVs/", mode: 'copy'

    input:
    path input_csv

    output:
    path "2_SamplesheetForTrimming.csv", emit: trim_sheet

    script:
    """
    python3 <<- EOF
    import csv
    input_csv = '${input_csv}'
    output_trim = '2_SamplesheetForTrimming.csv'

    trimmomatic_params = {
        'MINLEN': '36',
        'LEADING': '30',
        'TRAILING': '30',
        'SLIDINGWINDOW': '4:20'
    }

    with open(input_csv, 'r') as input_file, open(output_trim, 'w', newline='') as to_be_trimmed:
        csvreader = csv.reader(input_file)
        csvWriter_to_be_trimmed = csv.writer(to_be_trimmed, quoting=csv.QUOTE_MINIMAL)

        header = next(csvreader)
        header_SamplesheetForTrimming = header + list(trimmomatic_params.keys())
        csvWriter_to_be_trimmed.writerow(header_SamplesheetForTrimming)

        for row in csvreader:
            processed_row = row + list(trimmomatic_params.values())
            csvWriter_to_be_trimmed.writerow(processed_row)
    EOF
    """
}

process WriteAssemblyCSV {
    tag "PREPARE CSVs FOR Assembly"
    publishDir "./CSVs/", mode: 'copy'

    input:
    path input_csv

    output:
    path "3_samplesheetForAssembly.csv", emit: assembly_sheet

    script:
    """
    python3 <<- EOF
    import csv
    import os

    input_csv = '${input_csv}'
    output_assembly = '3_samplesheetForAssembly.csv'
    trimmed_path = "./${params.outdir}/TrimmedREADS/"
 

    with open(input_csv, 'r') as input_file, open(output_assembly, 'w', newline='') as to_be_assembled:
        csvreader = csv.reader(input_file)
        csvwriter_to_be_assembled = csv.writer(to_be_assembled)

        next(csvreader)  # Skip header
        csvwriter_to_be_assembled.writerow(['patient_id', 'R1', 'R2'])

        for row in csvreader:
            patient_id = row[0]
            R1 = f'{trimmed_path}{patient_id}_1.trim.fastq.gz'
            R2 = f'{trimmed_path}{patient_id}_2.trim.fastq.gz'
            csvwriter_to_be_assembled.writerow([patient_id, R1, R2])
    EOF
    """
}

process WriteBamCSV {
    tag "PREPARE CSVs FOR Bam Files"
    publishDir "./CSVs/", mode: 'copy'

    input:
    path input_csv

    output:
    path "4_samplesheetForBamFiles.csv", emit: bam_sheet

    script:
    """
    python3 <<- EOF
    import csv

    input_csv = '${input_csv}'
    output_bam = '4_samplesheetForBamFiles.csv'
    bam_path = "./${params.outdir}/Mapping/"

    with open(input_csv, 'r') as input_file, open(output_bam, 'w', newline='') as raw_bam:
        csvreader = csv.reader(input_file)
        csvwriter_for_bam_files = csv.writer(raw_bam)

        next(csvreader)  # Skip header
        csvwriter_for_bam_files.writerow(['patient_id', 'BamFile'])

        for row in csvreader:
            patient_id = row[0]
            bam_file = f'{bam_path}{patient_id}_delMoro.bam'
            csvwriter_for_bam_files.writerow([patient_id, bam_file])
    EOF
    """
}

process WriteRecalCSV {
    tag "PREPARE CSVs FOR Recal Files"
    publishDir "./CSVs/", mode: 'copy'

    input:
    path input_csv

    output:
    path "5_samplesheetReclibFiles.csv", emit: recal_sheet

    script:
    """
    python3 <<- EOF
    import csv

    input_csv = '${input_csv}'
    output_recal = '5_samplesheetReclibFiles.csv'
    bam_path = "./${params.outdir}/Mapping/"

    with open(input_csv, 'r') as input_file, open(output_recal, 'w', newline='') as recal_bam:
        csvreader = csv.reader(input_file)
        csvwriter_for_recal_files = csv.writer(recal_bam)

        next(csvreader)  # Skip header
        csvwriter_for_recal_files.writerow(['patient_id', 'BamFile'])

        for row in csvreader:
            patient_id = row[0]
            bam_file = f'{bam_path}{patient_id}_delMoro.recal.bam'
            csvwriter_for_recal_files.writerow([patient_id, bam_file])
    EOF
    """
} 



process WriteVcfCSV {
    tag "PREPARE CSVs FOR VCF Files"
    publishDir "./CSVs/", mode: 'copy'

    input:
    path input_csv

    output:
    path "6_samplesheetvcfFiles.csv", emit: vcf_sheet

    script:
    """
    python3 <<- EOF
    import csv

    input_csv = '${input_csv}'
    output_vcf = '6_samplesheetvcfFiles.csv'
    bam_path = "./${params.outdir}/Variants/"

    with open(input_csv, 'r') as input_file, open(output_vcf, 'w', newline='') as vcf_files:
        csvreader = csv.reader(input_file)
        csvwriter_for_vcf_files = csv.writer(vcf_files)

        next(csvreader)  # Skip header
        csvwriter_for_vcf_files.writerow(['patient_id', 'vcFile'])

        for row in csvreader:
            patient_id = row[0]
            vcf_file = f'{bam_path}{patient_id}_delMoro.recal.HC.vcf.gz'
            csvwriter_for_vcf_files.writerow([patient_id, vcf_file])
    EOF
    """
}
