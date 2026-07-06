import vcfpy 
import argparse
import pandas as pd
import logging 
import os
from enum import Enum


def _extract_spliceai_hits(data_dict, key="SpliceAI", cutoff=0.5):
    results = []

    if key not in data_dict:
        return results

    for entry in data_dict[key]:
        parts = entry.split("|")
        #print(parts)

        # Safety check
        if len(parts) < 6:
            continue

        gene = parts[1]
        #alt_value = parts[0]

        try:
            alt_value = parts[0]
            f3 = float(parts[2])
            f4 = float(parts[3])
            f5 = float(parts[4])
            f6 = float(parts[5])
        except ValueError:
            continue

        results.append({
            "alt": alt_value,
            "gene": gene,
            "DS_AG": f3,
            "DS_AL": f4,
            "DS_DG": f5,
            "DS_DL": f6,

            # Per-score flags
            "DS_AG_flag": int(f3 > cutoff),
            "DS_AL_flag": int(f4 > cutoff),
            "DS_DG_flag": int(f5 > cutoff),
            "DS_DL_flag": int(f6 > cutoff),
        })
    return results

def read_vcf(vcf_path): 
    reader = vcfpy.Reader.from_path(vcf_path)
    return reader

def extrat_spliceai_info(vcf_object, cutoff_value, label): 
    list_of_splice_vars = []
    for record in vcf_object:         
        info = record.INFO
        # parse the delta scores (may return empty list)
        sp_ds = _extract_spliceai_hits(info, cutoff=cutoff_value) 
        if sp_ds:  # verify the list is not empty
            if len(record.ID) > 1: 
                raise RuntimeError(f"Expected a single ID per variant by finds more than one,\n reconsider splitting the variants before running the analysis.")
            sp_attr = {
                "var_id": record.ID[0],      # NEW: variant ID (e.g. rsID, or "." if absent)
                "chr": record.CHROM,
                "ref": record.REF,
                "pos": record.POS,
            }
            
            # merge the two dictionaries 
            for variant in sp_ds:
                data = sp_attr | variant | {"labels": label}
                list_of_splice_vars.append(data)
    return list_of_splice_vars
