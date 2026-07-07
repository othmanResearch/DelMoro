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
import warnings
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
lirical_module = module.resolve()
if not lirical_module.is_file():
    raise FileNotFoundError(f"parse_lirical.py module was not found in the workflow home: {script_dir}")


# verify parse_splice module file exists 
module = script_dir / "modules/parse_splice.py" 
splice_module = module.resolve()
if not splice_module.is_file():
    raise FileNotFoundError(f"parse_splice.py module was not found in the workflow home: {script_dir}")

# verify parse_vcf module file exists 
module = script_dir / "modules/parse_vcf.py" 
vcf_module = module.resolve()
if not vcf_module.is_file():
    raise FileNotFoundError(f"parse_vcf.py module was not found in the workflow home: {script_dir}")

sys.path.append(os.path.abspath(os.path.join(script_dir, '.', 'modules')))    # set before calling internal modles

# import customised module
from modules.parse_vep import *
from modules.parse_loftee import *
from modules.parse_lirical import *
from modules.parse_splice import *
from modules.parse_vcf import *

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

    vcfs = Parameter(
        "vcfs",
        help="Directory containing per sample vcf files",
        required=False,
        type=str,
    )

    loftee_out = Parameter(
        "loftee_out",
        help="Directory containing LOFTEE output files",
        required=True,
        type=str,
    )

    hgnc_map = Parameter(
        "hgnc_map",
        help="HGNC mapping between NCBI gene ids and ensembl gene ids",
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
        
        # ensures pairing to safely assign data to sample ids 
        self.vep_df = (self.input[0], self.vep_df)
        self.next(self.join)

    @step 
    def join(self, inputs): 
        #self.vep_missens = [inp.missens for inp in inputs] # recover the missens table
        self.entire_vep_dfs = [inp.vep_df for inp in inputs]  # recover thge general vep table 
        self.merge_artifacts(inputs, exclude=['vep_df'])
        self.next(self.read_vcfs)

    @step
    def read_vcfs(self):
        """Read per sample vcf files"""        
        self.vcf_paths_for_all_samples = []
        
        for id in self.sample_ids :
            path_to_vcf_files= "/".join([self.vcfs,"*"+id+"*.vcf.gz"])
            vcf_paths = glob.glob(path_to_vcf_files)
            
            # raise error if vcf file was not found
            if len(vcf_paths) == 0:
                raise FileNotFoundError(f"No VCF file was found for sample {id}")

            # raise error if more than one file was identified per sample 
            if len(vcf_paths) > 1: 
                raise ValueError(f"More than one VCF file match id: {id} in {self.vcfs} ")

            self.vcf_paths_for_all_samples.append((id, vcf_paths[0]))

        self.next(self.add_genotype_depth_information)  # will allow forking the processes 

    @step
    def add_genotype_depth_information(self):
        lookup = dict(self.entire_vep_dfs)
        self.entire_vep_dfs = []
        for id, vcf_path in self.vcf_paths_for_all_samples: 
            extracted_data = extract_vcf_genotype_data(vcf_path)

            # "." means that the datafame cannnot be used to join with vep
            if (n := (extracted_data["ID"] == ".").sum()) > 0:
                raise ValueError(f"The 'ID' column contains {n} invalid '.' value(s).")

            extracted_data = extracted_data[["ID", "GT", "DP"]].copy()
            
            # merge the DP and GT data 
            vep_with_dp_gt = lookup[id].merge(
                extracted_data,
                how="left",
                left_on="Uploaded_variation",
                right_on="ID")

            self.entire_vep_dfs.append( (id, vep_with_dp_gt) )
            del vep_with_dp_gt        
        self.next(self.get_high_impact_missens)

    @step 
    def get_high_impact_missens(self):
        self.vep_missens = []

        for id, vep_df in self.entire_vep_dfs:
            missens = filter_out_consequence(vep_df, consequence='missense_variant')
            classification, support_level = classify_variant_pathogenicity(missens)
            missens["classification"] = classification
            missens["classification_type"] = "prediction missens"
            missens["support_level"] = support_level
            missens = missens.query("classification == 'D' ")
            self.vep_missens.append( (id, missens) )
            del missens 

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

        self.next(self.read_lirical)
    
    @step 
    def read_lirical(self): 

        self.lirical_tsv_paths = []
        
        for id in self.sample_ids :
            path_to_lirical_tsv= "/".join([self.lirical_path,"*"+id+"*.tsv"])
            lirical_tsv_abs_path = glob.glob(path_to_lirical_tsv)
            
            # raise error if vep file was not found
            if len(lirical_tsv_abs_path) == 0:
                warnings.warn(f"No TSV file was found for parsing LIRICAL data for sample {id}")

            # raise error if more than one file was identified per sample 
            if len(lirical_tsv_abs_path) > 1: 
                raise ValueError(f"More than one TSV file was detected for LIRICAL parsing, sample: {id} in {self.lirical_path} ")

            self.lirical_tsv_paths.append((id, lirical_tsv_abs_path[0]))
        
        self.next(self.process_lirical) 

    @step
    def process_lirical(self):
        # reading ncbi gene id to gene symbol + ensemble gene id maps 
        hgnc_map = pd.read_table(self.hgnc_map, dtype={"NCBI Gene ID(supplied by NCBI)": object})
        hgnc_map = hgnc_map[["NCBI Gene ID(supplied by NCBI)", "Approved symbol", "Ensembl ID(supplied by Ensembl)"]]
        self.lirical_transformed_dfs = []
        lookup = dict(self.entire_vep_dfs)
        
        if self.lirical_tsv_paths:
            for id, lirical_file_path in self.lirical_tsv_paths: 
                lirical_df = pd.read_table(lirical_file_path, comment="!")
                lirical_df = remove_ncbigene_prefix(lirical_df)
                
                lirical_merged = lirical_df.merge(hgnc_map,
                                 how="left",
                                 left_on="entrezGeneId",
                                 right_on="NCBI Gene ID(supplied by NCBI)")

                var_ids = []
                for var in lirical_merged["variants"]: 
                    variant = var.split(" ")[0]
                    var_identifiers = parse_variant(variant)

                    # add var identifiers consistent to the vcf ID column 
                    var_id = "chr"+var_identifiers[0]+"_"+var_identifiers[1]+"_"+var_identifiers[2]+"_"+var_identifiers[3]
                    var_ids.append(var_id)

                lirical_merged["var_ids"] = var_ids
                lirical_merged = lirical_merged[["var_ids", "diseaseCurie", "rank"] ].rename(columns={"rank": "lirical_rank"})

                merge_with_vep = lookup[id].merge(
                            lirical_merged,
                            how="inner",
                            left_on="Uploaded_variation",
                            right_on="var_ids")
                merge_with_vep["classification"] = 'D'
                merge_with_vep["classification_type"] = 'Phenotype matching'

                self.lirical_transformed_dfs.append( (id, merge_with_vep ) )

        self.next(self.assembl_dfs)
    
    @step
    def assembl_dfs(self):
        self.merged_dfs = []
        dic_missens = dict(self.vep_missens)
        dic_lof = dict(self.lof_dfs)
        dic_splicing = dict(self.matched_splicing_vars_dfs)
        dic_stop_loss = dict(self.stop_loss_dfs) 
        dic_clindign = dict(self.clinsign_dfs)
        dic_lirical = dict(self.lirical_transformed_dfs)

        for id in self.sample_ids:  
            # make sure that the second dataframe is not empty 
            if dic_lof[id].empty == False:
                merged_df = concatenate_dataframes(dic_missens[id], dic_lof[id])
            else: 
                merged_df = dic_missens[id]
            # merging splice ai data 
            merged_df = concatenate_dataframes(merged_df, dic_clindign[id], dic_splicing[id], dic_stop_loss[id], dic_lirical[id])

            self.merged_dfs.append(( id, merged_df)) 
            del merged_df

        self.next(self.filter_freq)

    @step
    def filter_freq(self):
        self.all_vars_filtered = []
        for id, var_df in self.merged_dfs :
            vars_freq_filtered =  filter_by_max_af(var_df, cutoff=0.05)
            self.all_vars_filtered.append((id, var_df[vars_freq_filtered]))

            var_df[vars_freq_filtered].to_csv("~/Desktop/vars_with_dp.csv")
        self.next(self.end)


    @step
    def end(self):
        print("Pipeline complete.")


if __name__ == "__main__":
    DataAggregator()
