#!/usr/bin/env python3

import pandas as pd
import numpy as np
from io import StringIO
from pathlib import Path
import glob


def vep_paths(sample_ids, vep_dir):
    """
    Find the unique VEP annotation file for each sample.

    Parameters
    ----------
    sample_ids : iterable of str
        Sample identifiers.
    vep_dir : str or Path
        Directory containing VEP TSV files.

    Returns
    -------
    list[tuple[str, str]]
        List of (sample_id, vep_file_path) tuples.

    Raises
    ------
    FileNotFoundError
        If no VEP file is found for a sample.
    ValueError
        If more than one VEP file matches a sample.
    """
    vep_dir = Path(vep_dir)
    vep_paths_for_all_samples = []

    for sample_id in sample_ids:
        matches = glob.glob(str(vep_dir / f"*{sample_id}*.tsv"))

        if not matches:
            raise FileNotFoundError(
                f"No VEP annotation file was found for sample '{sample_id}'."
            )

        if len(matches) > 1:
            raise ValueError(
                f"Multiple VEP annotation files match sample '{sample_id}' "
                f"in '{vep_dir}'."
            )

        vep_paths_for_all_samples.append((sample_id, matches[0]))

    return vep_paths_for_all_samples

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


def filter_out_consequence(df, consequence='missense_variant'):
    """
    retains rows from a dataframe where the "Consequence" column 
    contains a specific consequence (including when combined with other values).
    
    Parameters:
    -----------
    df : pd.DataFrame
        Input dataframe with a "Consequence" column
    consequence : str
        The consequence type to filter out (default: 'missense_variant')
    
    Returns:
    --------
    pd.DataFrame
        Filtered dataframe without rows containing the specified consequence
    """
    # Check if "Consequence" column contains the consequence string
    mask = df['Consequence'].astype(str).str.contains(
        consequence, 
        na=False, 
        case=False
    )
    
    # Return rows where the consequence is NOT found (negate the mask)
    return df[mask]

def filter_by_max_af(df, cutoff=0.05, missing_as_pass=False):
    """
    Create a boolean vector filtering rows by MAX_AF (allele frequency) values.
    
    Parameters:
    -----------
    df : pd.DataFrame
        Input dataframe with a "MAX_AF" column
    cutoff : float
        Allele frequency cutoff (default: 0.05)
    missing_as_pass : bool
        If True, missing values ("-") are treated as passing the filter (True)
        If False, missing values are treated as not passing the filter (False)
        (default: False)
    
    Returns:
    --------
    pd.Series (bool)
        Boolean vector where True indicates MAX_AF < cutoff
    """
    # Convert "-" to NaN first
    af_series = df['MAX_AF'].replace('-', pd.NA)
    
    # Convert to numeric (handles scientific notation and coerces errors to NaN)
    af_values = pd.to_numeric(af_series, errors='coerce')
    
    # Create boolean mask where values < cutoff
    mask = af_values < cutoff
    
    # Handle missing values
    if missing_as_pass:
        # NaN values become True (pass the filter)
        mask = mask.fillna(True)
    else:
        # NaN values become False (don't pass the filter)
        mask = mask.fillna(False)
    
    return mask

def classify_variant_pathogenicity(df):
    """
    Classify variants based on multiple prediction scores.
    
    Classification logic:
    - "D" (Deleterious): AlphaMissense shows P (Pathogenic) AND MetaRNN shows D
    - "T" (Tolerated): Otherwise
    - "not_applicable": Insufficient data
    
    Support levels (only for "D" variants):
    - 2: AlphaMissense=P AND MetaRNN=D
    - 3: AlphaMissense=P AND MetaRNN=D AND M-CAP=D
    
    Parameters:
    -----------
    df : pd.DataFrame
        Input dataframe with columns: M-CAP_pred, AlphaMissense_pred, MetaRNN_pred
    
    Returns:
    --------
    classification : np.array
        Array of "D", "T", or "not_applicable"
    support_level : np.array
        Array of support levels (0, 2, or 3; 0 for "T" and "not_applicable")
    """
    
    def get_worst_prediction(pred_string, predictor_type):
        """
        Extract the worst (most severe) prediction from comma-separated values.
        
        Returns: worst prediction or None if no valid prediction found
        """
        if pd.isna(pred_string):
            return None
        
        # Split by comma and clean whitespace
        predictions = [p.strip() for p in str(pred_string).split(',')]
        
        if predictor_type == 'AlphaMissense':
            # Severity: P > A > B
            severity = {'P': 3, 'A': 2, 'B': 1}
        else:  # MetaRNN or M-CAP
            # Severity: D > T
            severity = {'D': 2, 'T': 1}
        
        # Filter out dots and missing values
        valid_preds = [p for p in predictions if p and p != '.']
        
        if not valid_preds:
            return None
        
        # Return the prediction with highest severity
        worst = max(valid_preds, key=lambda x: severity.get(x, 0))
        return worst if severity.get(worst, 0) > 0 else None
    
    # Extract worst predictions for each predictor
    alpha_preds = df['AlphaMissense_pred'].apply(
        lambda x: get_worst_prediction(x, 'AlphaMissense')
    )
    metarnn_preds = df['MetaRNN_pred'].apply(
        lambda x: get_worst_prediction(x, 'MetaRNN')
    )
    mcap_preds = df['M-CAP_pred'].apply(
        lambda x: get_worst_prediction(x, 'M-CAP')
    )
    
    # Initialize output arrays
    n_rows = len(df)
    classification = np.empty(n_rows, dtype=object)
    support_level = np.zeros(n_rows, dtype=int)
    
    # Apply classification logic
    for i in range(n_rows):
        alpha = alpha_preds.iloc[i]
        metarnn = metarnn_preds.iloc[i]
        mcap = mcap_preds.iloc[i]
        
        # Check if we have enough data
        if alpha is None or metarnn is None:
            classification[i] = 'not_applicable'
            support_level[i] = 0
        # Classify as "D" if AlphaMissense=P AND MetaRNN=D
        elif alpha == 'P' and metarnn == 'D':
            classification[i] = 'D'
            # Determine support level
            if mcap == 'D':
                support_level[i] = 3  # All three support
            else:
                support_level[i] = 2  # AlphaMissense and MetaRNN support
        else:
            classification[i] = 'T'
            support_level[i] = 0
    
    return classification, support_level

def filter_clin_sig(df: pd.DataFrame, column: str = "CLIN_SIG") -> pd.DataFrame:
    """
    Filter a VEP DataFrame based on the CLIN_SIG column.

    A row is retained if at least one comma-separated CLIN_SIG value belongs
    to the list of clinically relevant values. Missing values are represented
    by '-'.

    Parameters
    ----------
    df : pd.DataFrame
        VEP DataFrame.
    column : str, default="CLIN_SIG"
        Name of the CLIN_SIG column.

    Returns
    -------
    pd.DataFrame
        Filtered DataFrame.
    """

    allowed = {
        "affects",
        "association",
        "confers_sensitivity",
        "drug_response",
        "established_risk_allele",
        "likely_pathogenic",
        "pathogenic",
        "pathogenic_low_penetrance",
        "likely_risk_allele",
        "risk_allele",
        "protective",
        "conflicting_interpretations_of_pathogenicity",
    }

    def keep(value):
        if pd.isna(value) or value == "-":
            return False

        values = {v.strip() for v in str(value).split(",")}
        return not allowed.isdisjoint(values)

    return df[df[column].apply(keep)].copy()


def concatenate_dataframes(*dfs: pd.DataFrame) -> pd.DataFrame:
    """
    Concatenate multiple DataFrames while keeping all columns.
    Missing columns in any DataFrame are added and filled with NaN.

    Parameters
    ----------
    *dfs : pd.DataFrame
        Two or more DataFrames to concatenate.

    Returns
    -------
    pd.DataFrame
        Concatenated DataFrame with the union of all columns.
    """
    if not dfs:
        raise ValueError("At least one DataFrame must be provided.")

    return pd.concat(
        dfs,
        axis=0,
        ignore_index=True,
        sort=False
    )
