#!/usr/bin/env python3
"""
Metaflow starter pipeline.

Parameters
----------
--samples          (-s)  Path to CSV file listing samples
--lirical_path      (-l)  Directory containing LIRICAL output
--vep_tab                 Directory containing VEP tab-delimited annotations
--spliceai_vcfs           Directory containing SpliceAI-annotated VCFs
--loftee_out              Directory containing LOFTEE output

Note: -s and -l were requested for two parameters each (samples/spliceai_vcfs
and lirical_path/loftee_out). Short flags must be unique, so -s and -l are
kept on `samples` and `lirical_path`; `spliceai_vcfs` and `loftee_out` use
long-form flags only.

Run e.g.:
    python pipeline.py run \
        --samples samples.csv \
        --lirical_path /data/lirical \
        --vep_tab /data/vep_tab \
        --spliceai_vcfs /data/spliceai_vcfs \
        --loftee_out /data/loftee_out
"""

import csv
import os
import pandas as pd
from metaflow import FlowSpec, Parameter, step


class DataAggregator(FlowSpec):

    samples = Parameter(
        "samples",
        help="Path to CSV file listing sample IDs / metadata",
        required=True,
        type=str,
    )

    lirical_path = Parameter(
        "lirical_path",
        help="Directory containing LIRICAL output files",
        required=True,
        type=str,
    )

    vep_tab = Parameter(
        "vep_tab",
        help="Directory containing VEP tab-delimited annotation files",
        required=True,
        type=str,
    )

    spliceai_vcfs = Parameter(
        "spliceai_vcfs",
        help="Directory containing SpliceAI-annotated VCF files",
        required=True,
        type=str,
    )

    loftee_out = Parameter(
        "loftee_out",
        help="Directory containing LOFTEE output files",
        required=True,
        type=str,
    )

    @step
    def start(self):
        """Validate inputs and load the sample sheet."""
        for path, name in [
            (self.samples, "samples"),
            (self.lirical_path, "lirical_path"),
            (self.vep_tab, "vep_tab"),
            (self.spliceai_vcfs, "spliceai_vcfs"),
            (self.loftee_out, "loftee_out"),
        ]:
            if not os.path.exists(path):
                raise FileNotFoundError(f"{name} path does not exist: {path}")

        with open(self.samples) as f:
            reader = csv.DictReader(f)
            self.sample_list = list(reader)

        print(f"Loaded {len(self.sample_list)} samples from {self.samples}")
        self.next(self.process_samples)

    @step
    def process_samples(self):
        """Placeholder for per-sample processing / annotation-merging logic."""
        # Example: fan out over samples in parallel with a foreach, e.g.
        #   self.next(self.per_sample, foreach='sample_list')
        for sample in self.sample_list:
            print(f"Processing sample: {sample}")
            # TODO: pull matching files from self.lirical_path, self.vep_tab,
            # self.spliceai_vcfs, self.loftee_out based on sample ID
        self.next(self.end)

    @step
    def end(self):
        print("Pipeline complete.")


if __name__ == "__main__":
    DataAggregator()
