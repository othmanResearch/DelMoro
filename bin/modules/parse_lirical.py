import pandas as pd

def remove_ncbigene_prefix(df: pd.DataFrame, column: str = "entrezGeneId") -> pd.DataFrame:
    """
    Remove the 'NCBIGene:' prefix from the specified column.

    Parameters
    ----------
    df : pd.DataFrame
        Input DataFrame.
    column : str, default="entrezGeneId"
        Name of the column containing NCBIGene identifiers.

    Returns
    -------
    pd.DataFrame
        The DataFrame with the updated column.
    """
    if column not in df.columns:
        raise KeyError(f"Column '{column}' not found in DataFrame.")

    df[column] = df[column].str.replace("NCBIGene:", "", regex=False)

    return df

import re

def parse_variant(variant: str) -> tuple[str, str, str, str]:
    """
    Parse a variant string of the form 'CHR:POSREF>ALT'.

    Parameters
    ----------
    variant : str
        Variant string (e.g., '8:43169228C>T').

    Returns
    -------
    tuple[str, str, str, str]
        (chromosome, position, reference, alternate)

    Raises
    ------
    ValueError
        If the variant string is not in the expected format.
    """
    match = re.fullmatch(r"([^:]+):(\d+)([A-Za-z]+)>([A-Za-z]+)", variant)

    if match is None:
        raise ValueError(
            f"Invalid variant format: '{variant}'. "
            "Expected format: 'CHR:POSREF>ALT' (e.g. '8:43169228C>T')."
        )

    return match.groups()

