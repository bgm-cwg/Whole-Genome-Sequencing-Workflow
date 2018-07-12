import "wgs_upstream_1SampleBAMs_gatk4.wdl" as sample_wf
import "revert_bam.wdl" as reverter
workflow wgs_upstream 
{
    #RESOURCES SECTION 
    File dbSNP_vcf
    File dbSNP_vcf_idx
    String known_indels_sites_VCF
    String known_indels_sites_idx
    String ref_fasta
	
    File ref_dict
    File scattered_calling_intervals_list

    #INPUT SECTION
    Map[String, Array[File]] input_bams 
    
    String tools					
    String base_name					 
    String res_dir

    String script_folder				   
    
    Int    bwa_threads								
    Int    samtools_threads

    #For every sample call the upstream sub-workflow
    scatter(key_value in input_bams)
    {
       String key_sampleName                      = key_value.left
       Array[File] value_bams_array               = key_value.right
       
       call reverter.bam_reverter
       {
          input:
            input_bams = value_bams_array,
            tools = tools,
            sampleName = key_sampleName
       } 
    }

    scatter(index in range(length(bam_reverter.reverted_bams)))
    {
       Int i = index
       Array[Array[String]] sample_reverted_bams = bam_reverter.reverted_bams[i]
       String sampleName = bam_reverter.sName[i]
 
       call CollectFilenames
       {
          input:
            filename_arrays = sample_reverted_bams,
            python_flatten  = script_folder + "/flatten_arrays.py"
       }

       call sample_wf.wgs
       {
          input:
            sampleName                       = sampleName,
            bams                             = CollectFilenames.bams,
            bwa_threads                      = bwa_threads,
            samtools_threads                 = samtools_threads,
            tools                            = tools,
            base_name                        = base_name,
            res_dir                          = res_dir,
            dbSNP_vcf                        = dbSNP_vcf,
            dbSNP_vcf_idx                    = dbSNP_vcf_idx,
            known_indels_sites_VCF           = known_indels_sites_VCF,
            known_indels_sites_idx           = known_indels_sites_idx,
            ref_fasta                        = ref_fasta,
            ref_dict                         = ref_dict,
            scattered_calling_intervals_list = scattered_calling_intervals_list
       }
    }
}


task CollectFilenames
{
    Array[Array[String]] filename_arrays
    File python_flatten

    command
    {
        echo "${sep='\n' filename_arrays}" > raw_array
        python ${python_flatten} < raw_array > file_of_filenames
    }

    output
    {
        Array[String] bams = read_lines("./file_of_filenames")
    }

    runtime
    {
       memory: "100MB"
       cpu: 1
    }
}
