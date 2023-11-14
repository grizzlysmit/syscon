This is my syscon project
=========================

## introduction

The pururpose of this code is to keep track of a lot of servers, and use them easily. There are four main functions  to use the servers.

 1. syscon.raku ssh `<key>` 
 1. syscon.raku ping `<key>` 
 1. syscon.raku get home `<key>` `[<args> ...]` `[-r|--recursive]`
 1. syscon.raku put home `<key>` `[<args> ...]` `[-r|--recursive]`
 
where 
 - `<key>`            is a key that idedentifies the the server. 
 - `[<args> ...]`     is a list of zero or more files to either get or put (using `scp`).
 - `[-r|--recursive]` is a pair of flages which if present will cause the file to be copied recursively,  good for coping directories and their content.


There are 10 utility functions:
 1. syscon.raku edit configs                                                                                                             
 1. syscon.raku list keys  `[<prefix>]`  `[-c|--color|--colour]` `[-l|--page-length[=Int]]` `[-p|--pattern=<Str>]` `[-e|--ecma-pattern=<Str>]`     
 1. syscon.raku list all  `[<prefix>]`  `[-c|--color|--colour]` `[-l|--page-length`[=Int]]` `[-p|--pattern=<Str>]` `[-e|--ecma-pattern=<Str>]`      
 1. syscon.raku list hosts  `[<prefix>]`  `[-c|--color|--colour]` `[-l|--page-length`[=Int]]` `[-p|--pattern=<Str>]` `[-e|--ecma-pattern=<Str>]`    
 1. syscon.raku list by both  `[<prefix>]`  `[-c|--color|--colour]` `[-l|--page-length`[=Int]]` `[-p|--pattern=<Str>]` `[-e|--ecma-pattern=<Str>]`  
 1. syscon.raku add `<key>` `<host>` `[<port>]`  `[-s|--set|--force]` `[-c|--comment=<Str>]`                                                       
 1. syscon.raku delete `<key>`   `[-o|--comment-out]`                                                                                        
 1. syscon.raku del `<key>`   `[-o|--comment-out]`                                                                                           
 1. syscon.raku comment `<key>` `<comment>`                                                                                                  
 1. syscon.raku alias `<key>` `<target>`   `[-s|--set|--force]` `[-d|--really-force|--overwrite-dirs]` `[-c|--comment=<Str>]`                      

where 
 - `edit configs`      Is a function for low level configuration of the two con fig files `~/.local/share/syscon/hosts.h_ts` and `~/.local/share/syscon/editors` it will open the files in your prefered editor `gvim` for me you can specify the editor to use in the `~/.local/share/syscon/editors` file,  it will use the first one theat is available. or you can specify the editor to use using these environment variables:

          * `GUI_EDITOR`   A vartiable I created for specifing ones preferred GUI editor. This takes precedence.
          * `VISUAL`       A standard variable used to indicate a prefered editor.
          * `EDITOR`       Another standard variable to denote a preffered editor.

 - `list keys`         Is a function to list all or some of the keys in `~/.local/share/syscon/hosts.h_ts` if `<prefix>` is present only list those keys starting with that prefix,  

