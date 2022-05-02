codefresh.sh included functions:                                                                     
                                                                                                         
|||                                                                                                      
|----------:|:-------------|                                                                             
| sa_token() | decode pod's sa jwt                                                                       
| ns() | set or display current namespace                                                                
|  get_trigger() | get trigger used for the last or specific build                                       
|  pipid() | set PIPID variable by running latest 'cf get pip' from history                              
| cf_token() | get token of the specific or current context                                              
| cf_api_key() | set CF_API_KEY var from the cf_token() output |                                         
| keys() | wrapper around jq(1) displays keys by default                                                 
                                                                                                         
 Useful for quick review of the json files, i.e:                                                         
                                                                                                         
     cat pipeline.json | keys    # only top level keys                                                   
     cat pipeline.json | keys spec   # all the values under .spec                                        
     cat pipeline.json | keys spec.steps.   # only keys under steps, note the "dot"                      
                                                                                                         
* * *                                                                                                    
                                                                                                         
`git_convert_remote.sh` - converts git remote specification from https to ssh  and vice versa and perform
s inline edits                                                                                           
                                                                                                         
* * *                                                                                                    
`bash_functions.sh` - includes system helper functions                                                   
|||                                                                                                      
|----------:|:-------------|                                                                             
| dir() | searches for the pattern in files in current directory (default)                               
Wrapper around find(1).                                                                                  
                                                                                                         
    Usage: [GREP_OPTS] dir [DIR] [DEPTH] EXPR                                                            
                                                                                                         
Arguments can be used interchangeably, see comments for details.                                         
                                                                                                         

