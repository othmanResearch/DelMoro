#!/usr/bin/env python3

import pandas as pd
import numpy as np
from io import StringIO

def read_vep_file(filepath):
    """
    Read a VEP TSV file, skipping metadata lines (##) while keeping header (#).
    
    Parameters:
    -----------
    filepath : str
        Path to the VEP TSV file
    
    Returns:
    --------
    pd.DataFrame
        DataFrame with VEP data and cleaned column names
    """
    # Read file and filter out lines starting with "##"
    with open(filepath, 'r') as f:
        lines = [line for line in f if not line.startswith('##')]
    
    # Merge filtered lines into a single string
    filtered_content = ''.join(lines)
    
    # Read into pandas dataframe
    df = pd.read_csv(
        StringIO(filtered_content),
        sep='\t'
    )
    
    # Remove leading '#' from column names
    df.columns = df.columns.str.lstrip('#')
    
    return df
