// Module files for DelMoro pipeline

// Generate CSV ;

process WriteCSV {
    publishDir "./CSVs/", mode: 'copy'
    tag "PREPARE CSVs FOR DelMoro"

    input:
    path input_csv

    output:
    path "2_SamplesheetForTrimming.csv", emit: trim_sheet
    path "3_samplesheetForAssembly.csv", emit: assembly_sheet
    path "4_samplesheetForBamFiles.csv", emit: bam_sheet

    script:
    """
    python3 <<- EOF
    import csv
    import os

    input_csv = '${input_csv}'
    output_trim = '2_SamplesheetForTrimming.csv'
    output_assembly = '3_samplesheetForAssembly.csv'
    output_bam = '4_samplesheetForBamFiles.csv'
    trimmed_path = "./outdir/TrimmedREADS/"
    bam_path = "./outdir/Mapping/"

    def process_file_name(file_name):
        file_name = file_name.replace('./Data/', '')
        if file_name.endswith('.gz'):
            file_name = os.path.splitext(file_name)[0]
        return file_name

    with open(input_csv, 'r') as input_file, \
            open(output_trim, 'w', newline='') as to_be_trimmed, \
            open(output_assembly, 'w', newline='') as to_be_assembled, \
            open(output_bam, 'w', newline='') as to_variant_Calling:

        csvreader = csv.reader(input_file)
        csvWriter_to_be_trimmed = csv.writer(to_be_trimmed, quoting=csv.QUOTE_MINIMAL)
        csvwriter_to_be_assembled = csv.writer(to_be_assembled)
        csvwriter_for_bam_files = csv.writer(to_variant_Calling)

        # Read header from input CSV
        header = next(csvreader)

        # Write headers for output files
        header_SamplesheetForTrimming = header + ['MINLEN', 'LEADING', 'TRAILING', 'SLIDINGWINDOW']
        csvWriter_to_be_trimmed.writerow(header_SamplesheetForTrimming)

        # Write header for assembly CSV
        csvwriter_to_be_assembled.writerow(['patient_id', 'R1', 'R2'])

        # Write header for bam files
        csvwriter_for_bam_files.writerow(['patient_id', 'BamFile'])

        # Define Trimmomatic parameters
        trimmomatic_params = {
            'MINLEN': '36',
            'LEADING': '30',
            'TRAILING': '30',
            'SLIDINGWINDOW': "'4:20'"
        }

        # Continue processing the CSV file
        for row in csvreader:
            # Process the row for trimming
            processed_row = row + [trimmomatic_params[param] for param in trimmomatic_params]
            csvWriter_to_be_trimmed.writerow(processed_row)

            # Construct paths for assembly sheet
            patient_id = row[0]
            R1 = f'{trimmed_path}{process_file_name(row[1])}'  # Assuming R1 is in second column
            R2 = f'{trimmed_path}{process_file_name(row[2])}'  # Assuming R2 is in third column
            
            # Write row for assembly
            csvwriter_to_be_assembled.writerow([patient_id, R1, R2])

            # Construct BamFile path
            bam_file = f'{bam_path}{patient_id}_sor@RG@MD.bam'
            # Write row for bam files
            csvwriter_for_bam_files.writerow([patient_id, bam_file])
    EOF
    """
} 
