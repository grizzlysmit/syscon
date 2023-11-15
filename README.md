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
 1. syscon.raku alias `<key>` `<target>`   `[-s|--set|--force]` `[-d|--really-force|--overwrite-hosts]` `[-c|--comment=<Str>]`                      

where 
 - `edit configs`      Is a function for low level configuration of the two con fig files `~/.local/share/syscon/hosts.h_ts` and `~/.local/share/syscon/editors` it will open the files in your prefered editor `gvim` for me you can specify the editor to use in the `~/.local/share/syscon/editors` file,  it will use the first one theat is available. or you can specify the editor to use using these environment variables:

          * `GUI_EDITOR`   A vartiable I created for specifing ones preferred GUI editor.
                           This takes precedence.
          * `VISUAL`       A standard variable used to indicate a prefered editor.
          * `EDITOR`       Another standard variable to denote a preffered editor.

 - `list keys`         Is a function to list all or some of the keys in `~/.local/share/syscon/hosts.h_ts` where:

          * `<prefix>`                 If present only list those keys starting with that prefix.  
          * `-c|--color|--colour`      Is a flag to tell the program to use colour in the output.
          * `-l|--page-length[=Int]`   Sets  the page length after which a new header will be placed
                                       in the output. takes a int value (i.e. `--page-length=20`)
                                       (default 50).
          * `-p|--pattern=<Str>`       If supplied will filer the output based on the raku regex
                                       `<Str>` (default is `--pattern='^ .* $'`).
          * `-e|--ecma-pattern=<Str>`  Same as `--pattern` above except the pattern is in EcmaScript
                                       or JavaScript regex language. `--pattern` trumps this one if
                                       present, and is preferred due to imperfections in the
                                       `ECMA262Regex` modules translations of it to raku regex.

 - `list all`        Is the same as `list keys` except it shows you what the keys map to, **key `=>` host**, means key maps to host **host**,  where as **key --> target** is an alias with **target** being another key, this is like a symbolic link for hosts.
 - `list host`       Is the same again but the `<prefix>` and `--pattern` etc apply to the host side of the terms.
 - `list by both`    Is the same again but the `<prefix>` and `--pattern` etc apply to both the key and the host.
 - `add` `<key>` `<host>` `[<port>]`  `[-s|--set|--force]` `[-c|--comment=<Str>]`      Allows you to add a new **key `=>` host** pair to the `~/.local/share/syscon/hosts.h_ts` file,  where:

          * `<key>`                    Is the key to add.
          * `<host>`                   Is the host to add.
          * `<port>`                   Is an optional port (defaults to 22 if not present).
          * `-s|--set|--force`         If present tell the program to replace any mapping that
                                       already exist for `<key>`.
          * `-c|--comment=<Str>`       If present supplies the comment string for the entry.

 - `delete`  `<key>`   `[-o|--comment-out]`      Deletes or comments out a mapping. Where:

          * `-o|--comment-out`         Tells us to only comment the entry out rather than delete it.
                                       **TODO: add a function to uncomment it and a function to find
                                       all the commented out entries.**

 - `del` `<key>`   `[-o|--comment-out]`  Just an alias to delete.
 - `comment` `<key>` `<comment>`       adds comment `<comment>` to entry `<key>`.
 - `alias` `<key>` `<target>`   `[-s|--set|--force]` `[-d|--really-force|--overwrite-hosts]` `[-c|--comment=<Str>]`     Adds an alias to the file,  where:

          * `-s|--set|--force`                          Allows for overiting existing aliases.
          * `-d|--really-force|--overwrite-hosts`       Alows for overwriting **key `=>` host** pairs.
                                                        By default alias lacks that permission.


## Vanity functions

 1. syscon.raku tidy file                                                                                                                
 1. syscon.raku sort file                                                                                                                
 1. syscon.raku show file    `[-c|--color|--colour]`                                                                                       
 1. syscon.raku help    `[-n|--nocolor|--nocolour]` 


 - `tidy file`                            Tidies `~/.local/share/syscon/hosts.h_ts` so that every thing lines up pretty and neat.
 - `sort file`                            Sorts the file into order so that the keys will be ordered.
 - `show file`                            Shows the contents of the file.
 - `help` `-n|--nocolor|--nocolour`       Display usage by default coloured. unless `-n|--nocolor|--nocolour` are present in which case plain text will be output.


## Global options   -?|-h|--help

The global help option of `-?|-h|--help` display coloured usage details.


