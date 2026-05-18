#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

// params 

// Interactive Design while Running DelMoro

include {DelMoroWelcome	}	from './.logos' 
include {DelMoroParams	}	from './.logos' 
include {DelMoroHelp	} 	from './.logos' 

	       			             	 	
// channels 
  // prepare required csv from an intial csv
  PrepareCsv 		= params.basedon	? Channel.fromPath(params.basedon, checkIfExists: true)   			: Channel.empty()   	
 
  // Raw Reads to quality check 
  RawReads 		= params.rawreads 	? Channel.fromPath(params.rawreads, checkIfExists: true)       	
	       			             	 	  .splitCsv(header: true)  
       	       	                     		           .map { row -> tuple(row.patient_id, file(row.R1), file(row.R2)) }	: Channel.empty() 
       	       
  // Raw Reads to be trimmed based on required features  : MINLEN , LEADING, TRAILING, SLIDINGWINDOW
       	
  ReadsToBeTrimmed	= params.tobetrimmed 	? Channel.fromPath(params.tobetrimmed, checkIfExists: false)       	
	       						  .splitCsv(header: true)  
	       						   .map { row -> tuple(row.patient_id,
       		      					    file(row.R1), 
       		      				   	     file(row.R2), 
       		      				              row.MINLEN, 	
       		         				       row.LEADING,
       		         			 	        row.TRAILING,  
	           				         	 row.SLIDINGWINDOW ) }
	           				         	 .toSortedList { a, b -> a[0] <=> b[0] }   	 
                                      		   	          .flatMap { it }						: Channel.empty()
  // reference

  inputFileChannel 	= params.input ?: params.tobealigned
  // Trimmed reads      	       
  ReadsToBeAligned	= inputFileChannel	? Channel.fromPath(inputFileChannel, checkIfExists: false)       	
	       					 	  .splitCsv(header: true)  
       	      				          	   .map { row -> tuple(row.patient_id, file(row.R1), file(row.R2)) }
                               	     		  	    .toSortedList { a, b -> a[0] <=> b[0] }   	 
                                      		   	     .flatMap { it } 							: Channel.empty()
  // reference
  referFileChannel 	= params.reference 	?: params.igenome
  RefGenChannel		= referFileChannel 	? Channel.fromPath(referFileChannel).first()			: Channel.empty()
  
  // BamFiles channel				
  // used for base recalibration
  MappedReads		= params.bam	? Channel.fromPath(params.bam, checkIfExists: false)
  											  .splitCsv(header: true)
  											   .map { row ->
  											   		def bam       = file(row.BamFile)
  											   		def isRemote  = row.BamFile.startsWith('http')
  											   		def indexPath = bam.toString() + '.bai'
  											   		def indexFile = isRemote	? file("${row.BamFile}.bai")
  											   									: (	file("${row.BamFile}.bai").exists() ? file("${row.BamFile}.bai")
  											   																			: null )
  											   		if( !indexFile ) {
  											   			log.warn "Index file missing for BAM: ${bam}. Expected: ${indexPath}"
  											   			return null
  											   		}
  											   		tuple(row.patient_id, bam, indexFile)

  											}.filter { it != null }
  											  .toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }	: Channel.empty()
  											  
    // used for variant calling
    ToVarCall		= params.tovarcall	? Channel.fromPath(params.tovarcall, checkIfExists: false)
  											  	  .splitCsv(header: true)
                                   			  	   .map { row ->
  											   			def bam       = file(row.BamFile)
  											   			def isRemote  = row.BamFile.startsWith('http')
  											   			def indexPath = bam.toString() + '.bai'
  											   			def indexFile = isRemote	? file("${row.BamFile}.bai")
  											   									: (	file("${row.BamFile}.bai").exists() ? file("${row.BamFile}.bai")
  											   																			: null	)														
  											   			if (!indexFile.exists()) {
  											   				log.warn "Index file missing for BAM: ${bam}. Expected: ${indexPath}"
  											   				indexFile = null
  											   			}
  											   			tuple(row.patient_id, bam, indexFile)
  											   			}.filter { it != null }
  											   			.toSortedList { a, b -> a[0] <=> b[0] }.flatMap { it }	: Channel.empty()
    						
  // target bed file to extract coverage 
  Target 		= params.bedtarget	? Channel.fromPath(params.bedtarget, checkIfExists: true).first()	: Channel.value(file("NO_FILE"))
	
// KnownSite1 channel for BQSR

  KnownSite1 	= params.knownsite1	? Channel.fromPath(params.knownsite1, checkIfExists: false)
											  .map { vcfile ->
											  		def id       = vcfile.baseName
											  		def isRemote = params.knownsite1.startsWith('http')
											  		def tbi = file("${vcfile}.tbi")
											  		def idx = file("${vcfile}.idx")
											  		def indexFile = isRemote	? ( params.testKnS1Idx	? file(params.testKnS1Idx)	
											  															: ( tbi.exists() ? tbi : idx )
																				  )	: ( tbi.exists()	? tbi	: ( idx.exists() ? idx : null ) )
											  		if( !indexFile ) {
											  			log.warn "Missing index for ${vcfile}"
											  			return null
											  		}
											  		tuple(id, vcfile, indexFile)
											  	}.filter { it != null }.first()		: Channel.empty()
											  	
// KnownSite2 channel for BQSR

  KnownSite2  	= params.knownsite2	? Channel.fromPath(params.knownsite2, checkIfExists: false)
											  .map { vcfile ->
											  		def id       = vcfile.baseName
											  		def isRemote = params.knownsite2.startsWith('http')
											  		def tbi = file("${vcfile}.tbi")
											  		def idx = file("${vcfile}.idx")
											  		def indexFile = isRemote	? ( params.testKnS2Idx	? file(params.testKnS2Idx)
											  															: ( tbi.exists() ? tbi : idx )
																				  )	: ( tbi.exists()	? tbi	: ( idx.exists() ? idx : null )	)
											  		if( !indexFile ) {
											  			log.warn "Missing index for ${vcfile}"
											  			return null
											  		}
											  	tuple(id, vcfile, indexFile)
											}.filter { it != null }.first()		: Channel.empty()
    
 // VCF for Bcftools annotation
 
  AddRSID 			= params.rsid 	? Channel.fromPath(params.rsid, checkIfExists: false)
							  .map { vcfile ->
							      def id = vcfile.baseName
							      def tbi = vcfile.toString() + '.tbi'
							      def idx = vcfile.toString() + '.idx'
							      def indexFile = file(tbi).exists() ? file(tbi) : file(idx)
							      tuple(id, vcfile, indexFile)
							   }.first()								: Channel.empty()

 // Indexes Channels 

    // Aligner Indexs Bwa mem/2
  	AlignIdxRef 	= params.reference	? ( params.reference.startsWith('http')
    								? Channel.fromList(params.bwaTestIdx).map { file(it) }
    								: Channel.fromPath("${file(params.reference).getParent()}/*.{0123,amb,ann,bwt.2bit.64,pac,bwt,sa}",checkIfExists: false) ): Channel.empty()
    								
    //  Dictionary Indexs Bwa mem/2 
    DictIdxRef		= params.reference 	? ( params.reference.startsWith('http')
    								? Channel.value(file(params.dicTestIdx))
    								: Channel.fromPath("${file(params.reference).getParent()}/*.dict", checkIfExists: false)  ): Channel.empty()
       	
    // SamtoolsIndex
    SamtIdxRef 		= params.reference 	? ( params.reference.startsWith('http')
    								? Channel.value(file(params.samTestIdx))
    								: Channel.fromPath("${file(params.reference).parent}/${file(params.reference).name}.{fai,gzi}",checkIfExists: false )  ): Channel.empty()

       		 
  // Vep Annotations Channels
    
 
    VepSpecies		= params.species	?: ''     	 
    Assembly		= params.assembly 	?: ''	 
    CacheType 		= params.cachetype	?: ''
    CacheDir 		= params.cachedir 	?: ''
    CacheVersion	= params.cacheversion 	?: ''
    
    CacheDirANN		= CacheDir		? Channel.fromPath(params.cachedir , checkIfExists: false).first()		: Channel.empty()
  
  // vcf channels
  
    VcfChannel      	= params.toannotate 	? Channel.fromPath(params.toannotate, checkIfExists: false)
    							  						  .splitCsv(header: true)  
       	      			       		 	   				   .map { row -> tuple(row.patient_id, file(row.vcFile) ) }		: Channel.empty() 	 

    FilterChannel 		= params.tofilter 		? Channel.fromPath(params.tofilter, checkIfExists: false)
    							  						  .splitCsv(header: true)
    							  						   .map { row ->
    							  						   		def vcFile = file(row.vcFile)
    							  						   		def tbi = file("${vcFile}.tbi")
    							  						   		def idx = file("${vcFile}.idx")
    							  						   		def indexFile = tbi.exists() ? tbi : idx.exists() ? idx : null
    							  						   		tuple(row.patient_id, vcFile, indexFile) } 				: Channel.empty()
  // Reporting 
     	// Function to parse YAML file
	import groovy.yaml.YamlSlurper

 	def parseYamlFile(yamlFile) { new YamlSlurper().parse(yamlFile) }
    // DelMoro Logo Channel
    delmoroLogoCh 	= params.delmoroLogo	? Channel.fromPath(params.delmoroLogo)						: Channel.empty()
    // Patients Metadata with annotated Vcf paths Combined to Logo Channel
    metaPatiLogCh 	= params.metaPatients	? Channel.fromPath(params.metaPatients)
							  .splitCsv(header: true)
							   .map { row ->
							    	metaPatients = [
								    Identifier: row.Identifier,
								    SampleID: row.SampleID,
								    Sex: row.Gender,
								    Dob: row.Dob,
								    Ethnicity: row.Ethnicity,
								    Diagnosis: row.Diagnosis,
							    	]
							    	[metaPatients, file(row.vcFile)]   
								}.combine(delmoroLogoCh)					: Channel.empty()

    // Pipeline Executions step with Physician Metadata Parsing
    pipeExecYamlCh 	= params.metaYaml	? Channel.fromPath(params.metaYaml)
        						  .map { file -> parseYamlFile(file) }					: Channel.empty()
 
    // Combine both channels ( metaPatiLogCh with  pipeExecYamlCh ) 
    metaPipeExecYaml = params.metaPatients && params.metaYaml ? metaPatiLogCh.combine(pipeExecYamlCh)
                        						      .map { metaPatients, vcFile, delmoroLogo, pipeExecYamlCh -> 
										    [metaPatients, vcFile, delmoroLogo, pipeExecYamlCh]  
										}						: Channel.empty()
        
// subworkflows 

include { DelMoroSteps 		} from './DelMoroModesSw/DelMoroSteps.nf'
include { DelMoroFullSw 	} from './DelMoroModesSw/DelMoroFull.nf'
params.params = null
params.help = null
workflow {
        
    if (params.fullmode) {	 
	 	
	DelMoroFullSw(   RefGenChannel
		 	,ReadsToBeAligned
		 	,Target
		 	,KnownSite1
		 	,KnownSite2  
		 	,AddRSID
		 	)
  } else if (params.stepmode){

          DelMoroSteps(  PrepareCsv
			,RawReads
		 	,ReadsToBeTrimmed
		 	,RefGenChannel
		 	,AlignIdxRef
		 	,ReadsToBeAligned
		 	,Target
		 	,DictIdxRef
		 	,SamtIdxRef
		 	,MappedReads
		 	,KnownSite1
		 	,KnownSite2
		 	,AddRSID
		 	,ToVarCall
		 	,VepSpecies 
		 	,Assembly
		 	,CacheType
		 	,CacheDir
		 	,CacheVersion
		 	,VcfChannel
		 	,FilterChannel
		 	,CacheDirANN
		 	,metaPipeExecYaml) 
    } else if (params.params){
	DelMoroParams()
    } else if (params.help) {
       DelMoroHelp()
    } else {
      DelMoroWelcome()
    }
   
}
   	 


 
