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

import os
import glob
import sys
import pandas as pd
import logging
from pathlib import Path
from metaflow import FlowSpec, Parameter, step

# allow INFO level of logging
logging.basicConfig(level=logging.INFO)

# verify that the necessary modules are available within the workflow honme 
script_dir = Path(__file__).resolve().parent

# verify parse_vep module file exists
module = script_dir / "modules/parse_vep.py" 
vep_module = module.resolve()
if not vep_module.is_file():
    raise FileNotFoundError(f"parse_vep.py module was not found in the workflow home directory {script_dir}")

# verify parrse_loftee module file exists
module = script_dir / "modules/parse_loftee.py" 
loftee_module = module.resolve()
if not loftee_module.is_file():
    raise FileNotFoundError(f"parse_loftee.py module was not found in the workflow directory {script_dir}")

# verify parse_lirical module file exists 
module = script_dir / "modules/parse_lirical.py" 
vep_module = module.resolve()
if not vep_module.is_file():
    raise FileNotFoundError(f"parse_lirical.py module was not found in the workflow home: {script_dir}")


# verify parse_splice module file exists 
module = script_dir / "modules/parse_splice.py" 
vep_module = module.resolve()
if not vep_module.is_file():
    raise FileNotFoundError(f"parse_splice.py module was not found in the workflow home: {script_dir}")

print(os.path.abspath(os.path.join(script_dir, '.', 'modules')))
sys.path.append(os.path.abspath(os.path.join(script_dir, '.', 'modules')))    # set before calling internal modles

# import customised module
from modules.parse_vep import *
from modules.parse_loftee import *
from modules.parse_lirical import *
from modules.parse_splice import *

###########################################
#            WORKFLOW 
###########################################

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

        # read list of samples file 
        with open(self.samples, 'r') as f: 
            self.sample_ids = [ id.strip() for id in f.readlines()]

        print(f"Loaded {len(self.sample_ids)} samples")
        self.next(self.get_vep_paths)

    @step
    def get_vep_paths(self):
        """Placeholder for per-sample processing / annotation-merging logic."""
        
        self.vep_paths_for_all_samples = []
        
        for id in self.sample_ids :
            path_to_vep_files= "/".join([self.vep_tab,"*"+id+"*.tsv"])
            vep_paths = glob.glob(path_to_vep_files)
            
            # raise error if vep file was not found
            if len(vep_paths) == 0:
                raise FileNotFoundError(f"No VEP annotation file was found for sample {id}")

            # raise error if more than one file was identified per sample 
            if len(vep_paths) > 1: 
                raise ValueError(f"More than one file match id: {id} in {self.vep_tab} ")

            self.vep_paths_for_all_samples.append(vep_paths[0])

        self.next(self.process_vep_output, foreach='vep_paths_for_all_samples')  # will allow forking the processes 

    @step
    def process_vep_output(self):
        logging.info(f"Processing vep output for filtering missens variants")
        entire_df = read_vep_file(self.input)
        self.missens = filter_out_consequence(entire_df, consequence='missense_variant')
        classification, support_level = classify_variant_pathogenicity(self.missens)

        self.missens["classification"] = classification
        self.missens["classification_type"] = "prediction missens"
        self.missens["support_level"] = support_level
        self.next(self.join)

    @step 
    def join(self, inputs): 
        self.vep_dfs = [inp.missens for inp in inputs]
        self.merge_artifacts(inputs, exclude=['missens'])
        self.next(self.end)

    @step
    def end(self):
        print("Pipeline complete.")


if __name__ == "__main__":
    DataAggregator()
