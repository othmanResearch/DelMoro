#!/usr/bin/env python3


def filter_lof(df):
    """
    Filter Lof annotations with high confidence (HC)
    """
    the_df = df.copy()
    return the_df.query('LoF == "HC"')
