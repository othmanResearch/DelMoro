import csv
import os

# INPUT FILE GIVEN BY USER
input_csv = './CSVs/1_samplesheetForRawQC.csv'

# OUTPUTS
SamplesheetForTrimming = './CSVs/2_SamplesheetForTrimming.csv'
samplesheetForAssembly = './CSVs/3_samplesheetForAssembly.csv'
samplesheetForBamFiles = './CSVs/4_samplesheetForBamFiles.csv'

# Function to remove .gz extension and strip './Data/' from file name
def process_file_name(file_name):
    # Remove './Data/' from the file name if exists
    file_name = file_name.replace('./Data/', '')

    # Remove .gz extension if exists
    if file_name.endswith('.gz'):
        file_name = os.path.splitext(file_name)[0]  # Split file name into basename + extension
    return file_name

# Read input_csv >>> Generate OUTPUTS
with open(input_csv, 'r') as input_file, \
        open(SamplesheetForTrimming, 'w', newline='') as to_be_trimmed, \
        open(samplesheetForAssembly, 'w', newline='') as to_be_assembled, \
        open(samplesheetForBamFiles, 'w', newline='') as to_variant_Calling:

    csvreader = csv.reader(input_file)
    csvWriter_to_be_trimmed = csv.writer(to_be_trimmed, quoting=csv.QUOTE_MINIMAL)
    csvwriter_to_be_assembled = csv.writer(to_be_assembled)
    csvwriter_for_bam_files = csv.writer(to_variant_Calling)

    # Edit headers for all files
    header = next(csvreader)

    # Header for SamplesheetForTrimming CSV + add Trimmomatic parameters as columns
    # Define Trimmomatic parameters
    trimmomatic_params = {
        'MINLEN': '36',
        'LEADING': '30',
        'TRAILING': '30',
        'SLIDINGWINDOW': "'4:20'"  # Consistent format without quotes
    }

    header_SamplesheetForTrimming = header + list(trimmomatic_params.keys())
    csvWriter_to_be_trimmed.writerow(header_SamplesheetForTrimming)

    # Header for samplesheetForAssembly
    header_samplesheetForAssembly = header
    csvwriter_to_be_assembled.writerow(header_samplesheetForAssembly)

    # Header for samplesheetForBamFiles
    csvwriter_for_bam_files.writerow(['patient_id', 'BamFile'])  # Updated header to match required format

    # Raw Processing
    # Processing SamplesheetForTrimming
    for row in csvreader:
        patient_id, R1, R2 = row[0], row[1], row[2]

        # Write to SamplesheetForTrimming.csv to add parameters
        row_with_params = row + [
            trimmomatic_params['MINLEN'],
            trimmomatic_params['LEADING'],
            trimmomatic_params['TRAILING'],
            trimmomatic_params['SLIDINGWINDOW']
        ]

        csvWriter_to_be_trimmed.writerow(row_with_params)

        # Processing samplesheetForAssembly
        # Removes './Data/' + .gz >>> call process_file_name function
        Trimmed_R1 = process_file_name(R1)
        Trimmed_R2 = process_file_name(R2)

        # Add new path
        TrimmedPATH = './outdir/TrimmedREADS/'
        New_Path_Trimmed_R1 = f'{TrimmedPATH}{Trimmed_R1}'
        New_Path_Trimmed_R2 = f'{TrimmedPATH}{Trimmed_R2}'

        csvwriter_to_be_assembled.writerow([patient_id, New_Path_Trimmed_R1, New_Path_Trimmed_R2])

        # Processing samplesheetForBamFiles
        BamPATH = './outdir/Mapping/'
        BamFiles_suffix = f'{patient_id}_sor@RG@MD.bam'  # Append patient ID to suffix
        csvwriter_for_bam_files.writerow([patient_id, BamPATH + BamFiles_suffix])

print(f"CSV for reads to be trimmed saved to {SamplesheetForTrimming}")
print(f"CSV for reads to be assembled saved to {samplesheetForAssembly}")
print(f"CSV for BAM files saved to {samplesheetForBamFiles}")
