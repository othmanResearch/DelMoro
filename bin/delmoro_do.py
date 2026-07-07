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
            (self.spliceai_vcfs, "spliceai_vcfs")
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

            self.vep_paths_for_all_samples.append((id, vep_paths[0]))

        self.next(self.process_vep_output, foreach='vep_paths_for_all_samples')  # will allow forking the processes 

    @step
    def process_vep_output(self):
        logging.info(f"Processing vep output for filtering missens variants for sample {self.input[0]}")
        self.vep_df = read_vep_file(self.input[1])
        # add the sample id to the dataframe 
        self.vep_df["sample_id"] = self.input[0]
        self.missens = filter_out_consequence(self.vep_df, consequence='missense_variant')
        classification, support_level = classify_variant_pathogenicity(self.missens)
        self.missens["classification"] = classification
        self.missens["classification_type"] = "prediction missens"
        self.missens["support_level"] = support_level
        
        # ensures pairing to safely assign data to sample ids 
        self.missens = (self.input[0], self.missens)
        self.vep_df = (self.input[0], self.vep_df)
        self.next(self.join)

    @step 
    def join(self, inputs): 
        self.vep_missens = [inp.missens for inp in inputs] # recover the missens table
        self.entire_vep_dfs = [inp.vep_df for inp in inputs]  # recover thge general vep table 
        self.merge_artifacts(inputs, exclude=['missens', 'vep_df'])
        self.next(self.process_clinsign)
    
    @step
    def process_clinsign(self): 
        """ Variants labeled in CLIN_SIG colukn as  affects, association, confers_sensitivity, 
        drug_response, established_risk_allele ,likely_pathogenic, pathogenic, pathogenic_low_penetrance,
        likely_risk_allele, risk_allele, protective, conflicting_interpretations_of_pathogenicity will abe retained """

        self.clinsign_dfs = []
        for df in self.entire_vep_dfs:
            filtered_clin = filter_clin_sig(df[1]) 
            filtered_clin["classification"]= 'D'
            filtered_clin["classification_type"] = 'clinical significance'

            self.clinsign_dfs.append( ( df[0], filtered_clin) ) # ensures sanity of pairing between data and sample ids

        self.next(self.process_lof)

    @step 
    def process_lof(self): 
        self.lof_dfs = []
        for vep_df in self.entire_vep_dfs: 
            lof_vars  = filter_lof(vep_df[1])
            lof_vars["classification"] = 'D'
            lof_vars['classification_type'] = 'Loss of Function'

            self.lof_dfs.append( (vep_df[0], lof_vars) )
            del lof_vars # just in case something went silently wrong, the lof_vars won't recycle 
        self.next(self.get_spliceai_files)

    @step
    def get_spliceai_files(self): 
        """ a step for reading the paths for vcf files containing apliceai data  """
        

        self.spliceai_vcf_paths_for_all_samples = []
        
        for id in self.sample_ids :
            path_to_spliceai_vcf_file= "/".join([self.spliceai_vcfs,"*"+id+"*.vcf.gz"])
            spliceai_vcf_abs_path = glob.glob(path_to_spliceai_vcf_file)
            
            # raise error if vep file was not found
            if len(spliceai_vcf_abs_path) == 0:
                raise FileNotFoundError(f"No VCF file was found for parsing spliceAI data for sample {id}")

            # raise error if more than one file was identified per sample 
            if len(spliceai_vcf_abs_path) > 1: 
                raise ValueError(f"More than one VCF file for spliceAI parsing, match id: {id} in {self.vep_tab} ")

            self.spliceai_vcf_paths_for_all_samples.append((id, spliceai_vcf_abs_path[0]))


        self.next(self.collect_spliceai_high_impact_variants)

    @step 
    def collect_spliceai_high_impact_variants(self): 

        lookup = dict(self.entire_vep_dfs)
        self.matched_splicing_vars_dfs= []
        self.unmatched_splicing_dfs = []

        for id, path in self.spliceai_vcf_paths_for_all_samples: 
            flag_cols = ["DS_AG_flag", "DS_AL_flag", "DS_DG_flag", "DS_DL_flag"]
            vcf_obj = read_vcf(path)
            vars = extrat_spliceai_info(vcf_obj, cutoff_value = 0.5 , label = id) 
            if vars:
                vars_df = pd.DataFrame(vars)
                vars_df["any_flag"] = (vars_df[flag_cols] == 1).any(axis=1).astype(int)
                # selecting IDs of splicing variants 
                splicing_vars = vars_df.query("any_flag == 1")
                
                # looking the matching variants with the vep annotation table and the unmatched variants 
                vep_table = lookup[id]
                matching_rows = vep_table[vep_table["Uploaded_variation"].isin(splicing_vars["var_id"]) ]
                unmatched_splicing = splicing_vars[~splicing_vars["var_id"].isin(vep_table["Uploaded_variation"])] 
                
                # prepare for merging 
                matching_rows["classification"] = 'D'
                matching_rows["classification_type"] = 'splicing'

                self.matched_splicing_vars_dfs.append( (id, matching_rows) )
                self.unmatched_splicing_dfs.append((id, unmatched_splicing))

                del matching_rows
                del unmatched_splicing

        self.next(self.get_stop_loss)

    @step
    def get_stop_loss(self):
        self.stop_loss_dfs = []
        for id, vep_df in self.entire_vep_dfs : 
            stop_loss_vars = vep_df[vep_df["Consequence"].str.contains("stop_lost", na=False)]

            if stop_loss_vars.empty == False: 
                stop_loss_vars["classification"] = 'D'
                stop_loss_vars["classification_type"] = 'stop loss'

                self.stop_loss_dfs.append((id, stop_loss_vars))

        
        self.next(self.end) 


    @step
    def end(self):
        print("Pipeline complete.")


if __name__ == "__main__":
    DataAggregator()
