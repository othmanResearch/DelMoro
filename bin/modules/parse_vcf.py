import vcfpy
import pandas as pd


def extract_vcf_genotype_data(vcf_path, extra_fields=None):
    """
    Extract per-sample GT, DP, and AB data from a VCF file into a tidy
    pandas DataFrame (one row per variant x sample combination).

    Parameters
    ----------
    vcf_path : str
        Path to the VCF (or bgzipped VCF, .vcf.gz) file.
    extra_fields : list of str, optional
        Extra per-sample FORMAT field names to pull in addition to the
        defaults (GT, DP, AB), e.g. ["AD", "GQ", "PL"].

    Returns
    -------
    pandas.DataFrame
        Columns: CHROM, POS, ID, REF, ALT, sample, GT, DP
        (plus any additional fields requested), one row per
        variant/sample pair.
    """
    reader = vcfpy.Reader.from_path(vcf_path)
    samples = reader.header.samples.names

    fields_to_pull = ["GT", "DP", "AB"] + (list(extra_fields) if extra_fields else [])

    rows = []
    for record in reader:
        chrom = record.CHROM
        pos = record.POS
        # record.ID is a list of IDs (VCF allows semicolon-separated IDs);
        # join them, or fall back to "." if none are present
        variant_id = ";".join(record.ID) if record.ID else "."
        ref = record.REF
        alt = ",".join(a.value for a in record.ALT) if record.ALT else ""

        for call in record.calls:
            sample_name = call.sample
            row = {
                "CHROM": chrom,
                "POS": pos,
                "ID": variant_id,
                "REF": ref,
                "ALT": alt,
                "sample": sample_name,
            }
            for field in fields_to_pull:
                value = call.data.get(field, None)
                # GT comes back as e.g. "0/1" or "0|1" already as a string
                if field == "GT" and value is not None:
                    row["GT"] = value
                else:
                    row[field] = value
            rows.append(row)

    reader.close()

    df = pd.DataFrame(rows)
    return df
