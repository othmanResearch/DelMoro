def printOutput() { 
log.info"""

\033[37m  DDDDDDDDDDDDD                           \033[37mLLLLLLLLLLL             \033[31mMMMMMMMM               MMMMMMMM                                                      
\033[37m  D::::::::::::DDD                        \033[37mL:::::::::L             \033[31mM:::::::M             M:::::::M                                                      
\033[37m  D:::::::::::::::DD                      \033[37mL:::::::::L             \033[31mM::::::::M           M::::::::M                                                      
\033[37m  DDD:::::DDDDD:::::D                     \033[37mLL:::::::LL             \033[31mM:::::::::M         M:::::::::M                                                      
\033[37m   D:::::D    D:::::D    eeeeeeeeeeee     \033[37mL:::::L                 \033[31mM::::::::::M       M::::::::::M\033[37m   ooooooooooo   rrrrr   rrrrrrrrr      ooooooooooo   
\033[37m   D:::::D     D:::::D  ee::::::::::::ee  \033[37mL:::::L                 \033[31mM:::::::::::M     M:::::::::::M\033[37m oo:::::::::::oo r::::rrr:::::::::r   oo:::::::::::oo 
\033[37m   D:::::D     D:::::D e::::::eeeee:::::ee\033[37mL:::::L                 \033[31mM:::::::M::::M   M::::M:::::::M\033[37mo:::::::::::::::or:::::::::::::::::r o:::::::::::::::o
\033[37m   D:::::D     D:::::De::::::e     e:::::e\033[37mL:::::L                 \033[31mM::::::M M::::M M::::M M::::::M\033[37mo:::::ooooo:::::orr::::::rrrrr::::::ro:::::ooooo:::::o
\033[37m   D:::::D     D:::::De:::::::eeeee::::::e\033[37mL:::::L                 \033[31mM::::::M  M::::M::::M  M::::::M\033[37mo::::o     o::::o r:::::r     r:::::ro::::o     o::::o
\033[37m   D:::::D     D:::::De:::::::::::::::::e \033[37mL:::::L                 \033[31mM::::::M   M:::::::M   M::::::M\033[37mo::::o     o::::o r:::::r     rrrrrrro::::o     o::::o
\033[37m   D:::::D     D:::::De::::::eeeeeeeeeee  \033[37mL:::::L                 \033[31mM::::::M    M:::::M    M::::::M\033[37mo::::o     o::::o r:::::r            o::::o     o::::o
\033[37m   D:::::D    D:::::D e:::::::e           \033[37mL:::::L         LLLLLLLL\033[31mM::::::M     MMMMM     M::::::M\033[37mo::::o     o::::o r:::::r            o::::o     o::::o
\033[37m DDD:::::DDDDD:::::D  e::::::::e          \033[37mLL:::::::LLLLLLLLL:::::L\033[31mM::::::M               M::::::M\033[37mo:::::ooooo:::::o r:::::r            o:::::ooooo:::::o
\033[37m D:::::::::::::::DD    e::::::::eeeeeeee  \033[37mL::::::::::::::::::::::L\033[31mM::::::M               M::::::M\033[37mo:::::::::::::::o r:::::r            o:::::::::::::::o
\033[37m D::::::::::::DDD       ee:::::::::::::e  \033[37mL::::::::::::::::::::::L\033[31mM::::::M               M::::::M\033[37m oo:::::::::::oo  r:::::r             oo:::::::::::oo 
\033[37m DDDDDDDDDDDDD            eeeeeeeeeeeeee  \033[37mLLLLLLLLLLLLLLLLLLLLLLLL\033[31mMMMMMMMM               MMMMMMMM\033[37m   ooooooooooo    rrrrrrr               ooooooooooo   

                                                                    
\033[37m                                                                        \033[31m X
\033[37m         o O        o O       o O       o o       o O        o O o       o                    o O       o       o O       o O      o O       o O    
\033[37m       o | | O    o | | O   o | | O   o | |O     o| | O    o | | | O      o                 o | | O   o | O   o | | O    o| | O  o | | O   o | | O
\033[37m O | | | | | | | O  | | | | O | | | | O | | o | O | | | | O  | | | | o O O O O O O O O O O O || | | | O | | | O | | | | O | | | |  | | | | | | | | | | O 
\033[37m       o | | o    O | | o   O | | o   O | o      O| | o    O | | | o          o             O | | o   O | o   O | | o   O | | o  O | | o   O | | o 
\033[37m         o o        O o       O o       O         O o        O o o             o              O o       O       O o       O o      O o       O o     
                                                                                \033[31m o o X\033[37m
                                                                                
\033[32m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
\033[32m ✔ ALIGNER indexes 	=\033[37m ${params.outdir}/Indexes/Reference
\033[32m ✔ Dictionary indexes 	=\033[37m ${params.outdir}/Indexes/Reference
\033[32m ✔ Samtools indexes 	=\033[37m ${params.outdir}/Indexes/Reference
\033[32m ✔ Threads 		=\033[37m ${params.cpus}
\033[32m~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	"""
	}
	
include {createIndex; createDictionary; createIndexSamtools} from '../../modules/3_ReferenceIndexing' 

workflow INDEXING_REF_GENOME {
take:
    ref_gen_channel

  main: 
  printOutput()
  createIndex(ref_gen_channel)
  createDictionary(ref_gen_channel)
  createIndexSamtools(ref_gen_channel)



  emit:
    createIndex.out.bwa_index
    createDictionary.out.gatk_dic
    createIndexSamtools.out.samtools_index


}
