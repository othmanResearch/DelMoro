// Generate CSVs in separate processes

process WriteTrimmingCSV {
    tag "PREPARE CSVs FOR Trimming"
    publishDir "./CSVs/", mode: 'copy'

    input:
        path input_csv

    output:
        path "2_SamplesheetForTrimming.csv",    emit: trim_sheet

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
        path "3_samplesheetForAssembly.csv",    emit: assembly_sheet

    script:
    """
    python3 <<- EOF
    import csv
    import os

    input_csv = '${input_csv}'
    output_assembly = '3_samplesheetForAssembly.csv'
    trimmed_path = "./${params.outdir}/TrimmedREADS/"

    def process_file_name(file_name):
        file_name = file_name.replace('./Data/', '')
        if file_name.endswith('.gz'):
            file_name = os.path.splitext(file_name)[0]
        return file_name

    with open(input_csv, 'r') as input_file, open(output_assembly, 'w', newline='') as to_be_assembled:
        csvreader = csv.reader(input_file)
        csvwriter_to_be_assembled = csv.writer(to_be_assembled)

        next(csvreader)  # Skip header
        csvwriter_to_be_assembled.writerow(['patient_id', 'R1', 'R2'])

        for row in csvreader:
            patient_id = row[0]
            R1 = f'{trimmed_path}{process_file_name(row[1])}'
            R2 = f'{trimmed_path}{process_file_name(row[2])}'
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
        path "4_samplesheetForBamFiles.csv",    emit: bam_sheet

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
            bam_file = f'{bam_path}{patient_id}_sor@RG@MD.bam'
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
        path "5_samplesheetReclibFiles.csv",    emit: recal_sheet

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
            bam_file = f'{bam_path}{patient_id}_sor@RG@MD.bam.recal.bam'
            csvwriter_for_recal_files.writerow([patient_id, bam_file])
    EOF
    """
}

