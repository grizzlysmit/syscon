Syscon, sc
==========

Table of Contents
-----------------

  * [NAME](#name)

  * [AUTHOR](#author)

  * [VERSION](#version)

  * [TITLE](#title)

  * [SUBTITLE](#subtitle)

  * [COPYRIGHT](#copyright)

  * [Introduction](#introduction)

    * [Motivations](#motivations)

  * [USAGE](#usage)

    * [The actual work horses of the library](#the-actual-work-horses-of-the-library)

      * [sc ssh](#sc-ssh)

      * [sc ping](#sc-ping)

      * [sc get home](#sc-get-home)

      * [sc put home](#sc-put-home)

    * [Utility functions](#utility-functions)

      * [sc edit configs](#sc-edit-configs)

      * [sc list keys](#sc-list-keys)

      * [sc list all](#sc-list-all)

      * [sc list trash](#sc-list-trash)

      * [sc trash](#sc-trash)

      * [sc empty trash](#sc-empty-trash)

      * [sc undelete](#sc-undelete)

      * [sc stats](#sc-stats)

      * [sc statistics](#sc-statistics)

      * [sc add](#sc-add)

      * [sc delete](#sc-delete)

      * [sc del](#sc-del)

      * [sc comment](#sc-comment)

      * [backup db](#backup-db)

      * [sc restore db](#sc-restore-db)

      * [sc menu restore db](#sc-menu-restore-db)

      * [sc list db backups](#sc-list-db-backups)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

    * [module Syscon](#the-syscon-library)

      * [say-list-keys(…)](#say-list-keys)

      * [list-by-all(…)](#list-by-all)

      * [list-db-backups(…)](#list-db-backups)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [USAGE](#usage)

      * [ssh(…)](#ssh)

      * [ping(…)](#ping)

      * [_get(…)](#_get) or [on raku.land _get](#-get)

      * [_put](#usage) or [on raku.land _get](#-put)

NAME
====

syscon, sc

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

v0.1.18

TITLE
=====

syscon, sc

SUBTITLE
========

A module **`Syscon`** and a program **`syscon`** or **`sc`** for short, which keeps tarck of assorted servers and helps to connect to them.

COPYRIGHT
=========

LGPL V3.0+ [LICENSE](/LICENSE)

Introduction
============

A module **`Syscon`** and a program **`syscon`** or **`sc`** for short, which keeps tarck of assorted servers and helps to connect to them.

[Top of Document](#table-of-contents)

Motivations
-----------

I have to keep track of many servers (> 100) but who can remember all the host names, and ports?? That is where this app comes in I can connect to a server by ssh by.

```bash
$ syscon.raku ssh <key>
```

or for short

```bash
$ sc ssh <key>
```

Equally you can use

```bash
$ sc put home <key> <files> ……
```

To run 

```bash
$ scp -P $port <files> …… $host:
```

  * Where 

    * **`$host`** is generally something like **`username@example.com`**

    * **`$port`** is a port number.

    * **key** is the key to retrieve the host and port form the server.

      * It's put home because I may add put <other-place> at a later date.

[Top of Document](#table-of-contents)

This is the app, you can find the modules docs [here](/docs/Syscon.md)

### USAGE

```bash
sc --help

Usage:
  sc ssh <key>
  sc ping <key>
  sc get home <key>  [<args> ...] [-r|--recursive] [-t|--to=<Str>]
  sc put home <key>  [<args> ...] [-r|--recursive] [-t|--to=<Str>]
  sc edit configs
  sc list keys  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc list all  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc list trash  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc trash   [<keys> ...]
  sc empty trash
  sc undelete   [<keys> ...]
  sc stats  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc statistics  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc add <key> <host> [<port>]  [-s|--set|--force] [-c|--comment=<Str>]
  sc delete   [<keys> ...] [-d|--delete|--do-not-trash]
  sc del   [<keys> ...] [-d|--delete|--do-not-trash]
  sc comment <key> <comment>
  sc alias <key> <target>   [-s|--set|--force] [-d|--really-force|--overwrite-hosts] [-c|--comment=<Str>]
  sc backup db    [-w|--win-format|--use-windows-formating]
  sc restore db  [<restore-from>]
  sc menu restore db  [<message>]  [-c|--color|--colour] [-s|--syntax]
  sc list db backups  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc list editors    [-f|--prefix=<Str>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc editors stats  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc list editors backups  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc backup editors    [-w|--use-windows-formatting]
  sc restore editors <restore-from>
  sc set editor <editor> [<comment>]
  sc set override GUI_EDITOR <value> [<comment>]
  sc menu restore editors  [<message>]  [-c|--color|--colour] [-s|--syntax]
  sc tidy file
  sc sort file
  sc show file    [-c|--color|--colour]
  sc help   [<args> ...] [-n|--nocolor|--nocolour] [--<named-args>=...]
```

![image not available here go to the github page](/docs/images/usage.png)

[Top of Document](#table-of-contents)

The actual work horses of the library
-------------------------------------

### sc ssh

Runs

```bash
ssh -p $port $host
```

by the **`ssh(…)`** function defined in **Syscon.rakumod**.

```bash
22:22:06 θ76° grizzlysmit@pern:~ $ sc  ssh rak
ssh -p 22 rakbat.local
Welcome to Ubuntu 23.10 (GNU/Linux 6.5.0-14-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

0 updates can be applied immediately.



Last login: Tue Jan  2 23:48:56 2024 from 192.168.188.11
06:55:31 grizzlysmit@rakbat:~ $
```

![image not available here go to the github page](/docs/images/sc-ssh.png)

Implemented as [**`ssh(…)`**](#ssh) in [module Syscon](#the-syscon-library).

[Top of Document](#table-of-contents)

### sc ping

Runs

```bash
7:02:58 θ83° grizzlysmit@pern:~ 7m29s $ sc ping kil
ping killashandra.local
PING killashandra.local (192.168.188.11) 56(84) bytes of data.
64 bytes from killashandra.local (192.168.188.11): icmp_seq=1 ttl=64 time=0.285 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=2 ttl=64 time=0.249 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=3 ttl=64 time=0.242 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=4 ttl=64 time=0.253 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=5 ttl=64 time=0.274 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=6 ttl=64 time=0.273 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=7 ttl=64 time=0.226 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=8 ttl=64 time=0.831 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=9 ttl=64 time=0.272 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=10 ttl=64 time=0.264 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=11 ttl=64 time=0.227 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=12 ttl=64 time=0.263 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=13 ttl=64 time=0.255 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=14 ttl=64 time=0.258 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=15 ttl=64 time=0.234 ms
64 bytes from killashandra.local (192.168.188.11): icmp_seq=16 ttl=64 time=0.220 ms
^C
--- killashandra.local ping statistics ---
16 packets transmitted, 16 received, 0% packet loss, time 15337ms
rtt min/avg/max/mdev = 0.220/0.289/0.831/0.141 ms
```

  * Where

    * **`$key`** a key in the db.

![image not available here go to the github page](/docs/images/ping.png)

Implemented as [**`ping(…)`**](#ping) in [module Syscon](#the-syscon-library).

```raku
multi sub MAIN('ping', Str:D $key --> int){
    if ping($key) {
        return 0;
    } else {
        return 1;
    }
}
```

[Top of Document](#table-of-contents)

### sc get home

Get some files on the remote system and deposit them here (in the directory the user is currently in).

```bash
$ sc get home $key --to=$to --recursive $files-on-remote-system……
```

  * Where

    * **`$key`** The key of the host to get files from.

    * **`$to`** The place to put the files defaults to **`.`** or here.

    * **`--recursive`** sets the recursive flag so the files will be copied recursively, allowing a whole file sub tree to be copied.

    * **`$files-on-remote-system……`** A list of files on the remote system to copy can be anywhere on the remote system (defaults to the logins home directory).

e.g.

```bash
13:38:11 θ62° grizzlysmit@pern:~/tmp $ mkdir scratch
mkdir: created directory 'scratch'
13:39:03 θ65° grizzlysmit@pern:~/tmp $ sc get home rak --to=scratch .bashrc /etc/hosts  
scp -P 22 rakbat.local:.bashrc scratch
.bashrc                                                                     100%   11KB   5.6MB/s   00:00    
scp -P 22 rakbat.local:/etc/hosts scratch
hosts                                                                       100%  313   294.9KB/s   00:00    
13:41:48 θ69° grizzlysmit@pern:~/tmp 9s $ exa -FlaahigHb --colour-scale --time-style=full-iso  scratch/
   inode Permissions Links Size User        Group       Date Modified                       Name
21366408 drwxrwxr-x      2    - grizzlysmit grizzlysmit 2024-01-10 13:41:48.618577861 +1100 ./
20447359 drwxr-xr-x     25    - grizzlysmit grizzlysmit 2024-01-10 13:39:03.449870034 +1100 ../
21380247 .rw-rw-r--      1 11Ki grizzlysmit grizzlysmit 2024-01-10 13:41:47.958559032 +1100 .bashrc
21380261 .rw-r--r--      1  313 grizzlysmit grizzlysmit 2024-01-10 13:41:48.622577975 +1100 hosts
```

![image not available here go to the github page](/docs/images/sc-get-home.png)

Using the **_get** function defined in **Syscon.rakumod** [See **`_get(…)`**](#_get) or [on raku.land **`_get(…)`**](#-get).

[Top of Document](#table-of-contents)

### sc put home

```bash
$ sc put home $key --to=$to --recursive $files……
```

  * Where

    * **`$key`** is as always the key to identify the host in question.

    * **`$to`** is the place to put the files on the rmote system.

    * **`--recursive`** sets the recursive flag so the files will be copied recursively, allowing a whole file sub tree to be copied.

    * **`$files`**…… is a list of files to copy to the remote server.

```bash
sc put home kil --to=tmp scratch/bug.raku  docs/Syscon.1 
scp -P 22 scratch/bug.raku docs/Syscon.1 grizzlysmit@killashandra.local:tmp
bug.raku                                           100% 3303   557.3KB/s   00:00
Syscon.1                                           100%  485     1.0MB/s   00:00
```

![image not available here go to the github page](/docs/images/sc-put-home.png)

Implemented as

```raku
multi sub MAIN('put', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _put('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}
```

  * Where

    * **`multi sub _put('home', Str:D $key, Bool :r(:$recursive) = False, Str:D :$to = '', *@args --` Bool) is export**> is a function in **Sysycon.rakumod** See [**`_put(…)`**](#_put) or [on raku.land **`_put(…)`**](#-put).

[Top of Document](#table-of-contents)

Utility functions
-----------------

### sc edit configs

```bash
$ sc edit configs
```

Implemented by the **`edit-configs`** function in the **GUI::Editors.rakumod** module. This open your configuration files in your preferred GUI editor, if you have one, if you don't have one of those setup it will try for a good substitute, failing that it will Fail and print an error message. 

Do not use this it's for experts only, instead use the **set-*(…)** functions below.

```raku
multi sub MAIN('edit', 'configs') returns Int {
   if edit-configs() {
       exit 0;
   } else {
       exit 1;
   } 
}
```

[Top of Document](#table-of-contents)

### sc list keys 

```bash
$ sc list keys --help

Usage:
  sc list keys [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]

$ sc list keys

key     # comment                                            
=============================================================
a-qu    # diverse stuff including /functions/organiser/*.pl  
a1-dev  # a1-dev old system                                  
boh     # bohcif8iew8e@agent-bohcif8iew8e                    
bronze  # stuff like importnewaddress                        
infi    # inifidisk                                          
jei     # old jei                                            
jei-app # old jei                                            
kil     # killashandra.local on my lan                       
kill    # killashandra.local on my lan                       
killa   # killashandra.local on my lan                       
per     # pern.local on my lan                               
ph      # Errbot is here                                     
phone   # Errbot is here                                     
pknock  # the old port knocking                              
rak     # rakbat.local on my lan                             
rel     # The relation stuff                                 
rk      # rakbat.local on my lan                             
scripts # The scripts server.                                
=============================================================
```

![image not available here go to the github page](/docs/images/sc-list-keys.png)

[For the implemention see say-list-keys(…)](#say-list-keys)

[Top of Document](#table-of-contents)

### sc list all

```bash
10:11:16 θ68° grizzlysmit@pern:~/Projects/raku/syscon main 2s ± sc list all --pattern=" ^ .* 'sc' .* $ "

key     sep host                                                         : port # comment              
=======================================================================================================
scripts  => scripts@man0-agent-quuvoo4ohcequuox.quuvoo4ohcequuox.0.88.io : 22   # The scripts server.  
=======================================================================================================
10:11:25 θ62° grizzlysmit@pern:~/Projects/raku/syscon main 2s ± sc list all --syntax

key     sep host                                                                             : port  # comment
==========================================================================================================================================================
a-qu     => agent@man0-agent-quuvoo4ohcequuox.quuvoo4ohcequuox.0.88.io                       : 22    # diverse stuff including /functions/organiser/*.pl
a1-dev   => api@man0-nodea0-contact0-dev.contacttrace.com.au                                 : 22    # a1-dev old system
boh      => bohcif8iew8e@agent-bohcif8iew8e.jeiheaxi2iu4phea.1.88.io                         : 54271 # bohcif8iew8e@agent-bohcif8iew8e
bronze   => bronze-aus@man0-bronze0-contact0.y21coin.com                                     : 22    # stuff like importnewaddress
infi     => vahfoom3iquahfah@man0-appnode-vahfoom3iquahfah.vahfoom3iquahfah.infinitedisk.com : 22    # inifidisk
jei      => jeiheaxi2iu4phea@appnode-jeiheaxi2iu4phea.jeiheaxi2iu4phea.1.88.io               : 22    # old jei
jei-app --> jei                                                                                      # old jei
kil     --> kill                                                                                     # killashandra.local on my lan
kill     => grizzlysmit@killashandra.local                                                   : 22    # killashandra.local on my lan
killa   --> kil                                                                                      # killashandra.local on my lan
per      => grizzlysmit@pern.local                                                           : 22    # pern.local on my lan
ph      --> phone                                                                                    # Errbot is here
phone    => agent@man0-agent-quuvoo4ohcequuox.quuvoo4ohcequuox.0.88.io                       : 22    # Errbot is here
pknock   => oztralia.com@man0-appnode0-oztralia0.oztralia.com                                : 22    # the old port knocking
rak      => rakbat.local                                                                     : 22    # rakbat.local on my lan
rel      => relation@man0-app0-contact0.contacttrace.com.au                                  : 22    # The relation stuff
rk      --> rak                                                                                      # rakbat.local on my lan
scripts  => scripts@man0-agent-quuvoo4ohcequuox.quuvoo4ohcequuox.0.88.io                     : 22    # The scripts server.
==========================================================================================================================================================
```

![image not available here go to the github page](/docs/images/sc-list-by-all.png)

[For the implemention see list-by-all(…)](#list-by-all)

[Top of Document](#table-of-contents)

### sc list trash

```bash
sc list trash --help

Usage:
  sc list trash [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]

18:14:34 θ69° grizzlysmit@pern:~/Projects/raku/syscon main 2s ± sc list trash --syntax

#key        sep host                        : port # comment          
======================================================================
#dmy        --> dummy                              # an example line  
#dummy       => dummy@example.com           : 22   # an example line  
#dund       --> dunderhead                         # an example line  
#dunderhead  => dunderhead@again.emaple.com : 345  # an example line  
#ex          => grizzlysmit@example.com     : 344  # an example host  
======================================================================
```

![image not available here go to the github page](/docs/images/sc-list-trash--help.png)

[Top of Document](#table-of-contents)

### sc trash

```raku
sc trash --help
```

![image not available here go to the github page](/docs/images/sc-trash--help.png)

```raku
sc trash
```

![image not available here go to the github page](/docs/images/sc-trash.png)

[Top of Document](#table-of-contents)

### sc empty trash

```bash
sc empty trash --help
```

![image not available here go to the github page](/docs/images/sc-empty-trash.png)

[Top of Document](#table-of-contents)

### sc undelete

```bash
sc undelete --help
```

![image not available here go to the github page](/docs/images/sc-undelete.png)

[Top of Document](#table-of-contents)

### sc stats

```bash
sc stats
```

![image not available here go to the github page](/docs/images/sc-stats.png)

### sc statistics

An alias of stats see above [sc stats](#sc-stats).

[Top of Document](#table-of-contents)

### sc add

```bash
sc add <key> <host> [<port>]  [-s|--set|--force] [-c|--comment=<Str>]
```

  * Where

    * **`<key>`** is a unused key unless you use one of **`-s|--set|--force`** in which case it will overwrite the old value.

    * **`<host>`** is a host spec of the form **username@dns-address-or-host-name**.

    * **`<port>`** is a port number, if not present defaults to **22**.

    * If **-s**, **--set** or **--force** is present you can overwrite existing entries use with care.

    * If **-c** or **--comment** are present then **`<Str>`** should be a comment string to go with the entry.

      * Example use.

        ![sc add ex grizzlysmit@example.com 344 --comment="an example host"](/docs/images/sc-add.png)

[Top of Document](#table-of-contents)

### sc delete

A command to delete a row in the db i.e. a key and details, by default it just trashes the key but if **-d**, **--delete** or **--do-not-trash** is present it will really delete. 

```bash
sc delete --help

Usage:                                                                                                                                                
  sc delete [<keys> ...] [-d|--delete|--do-not-trash]
```

  * Where

    * **`[<keys> ...]`** is a optional list of keys if none are provided then the command does nothing 

    * **`[-d|--delete|--do-not-trash]`** is a flag to really delete, not trash them see [see](#sc-trash).

### sc del 

An alias for delete 

```bash
 sc del --help

Usage:                                                                                                                                                
  sc delete [<keys> ...] [-d|--delete|--do-not-trash]                                                                                                 
  sc del [<keys> ...] [-d|--delete|--do-not-trash]
```

[Top of Document](#table-of-contents)

### sc comment

Add or set a comment to a db entry. 

```bash
sc comment --help

Usage:
  sc comment <key> <comment>
```

  * Where

    * **`<key>`** An existing key in the db.

    * **`<comment>`** The comment to add.

[Top of Document](#table-of-contents)

### sc alias

```bash
sc alias --help

Usage:                                                                                                                                                
  sc alias <key> <target>  [-s|--set|--force] [-d|--really-force|--overwrite-hosts] [-c|--comment=<Str>]
```

  * Where

    * **`<key>`** is a new key to add or an exiting one to overwrite if you use **-s**, **--set** or **--force**.

      * **NB:** **-s**, **--set** or **--force** only work for **aliases** to overwrite **hosts** use **-d**, **--really-force** or **--overwrite-hosts**.

    * **`<target>`** Either a existing host or alias, it is an error if **`<target>`** does not exist.

    * **-s**, **--set** or **--force** mean overwrite any existing **`<key>`** if it is an alias.

    * **-d**, **--really-force** or **--overwrite-hosts** means overwrite anything regardless, use with care.

[Top of Document](#table-of-contents)

### backup db

Backup the file which is the db for this little app, I could use a *real* db but as it's just one simple table, I don't need that.

```bash
 sc backup db --help

Usage:
  sc backup db  [-w|--win-format|--use-windows-formating]
```

  * Where

    * **-w**, **--win-format** or **--use-windows-formating** means that the '**:**' in the date time will be replaced with '**.**' and the '**.**' the decimal point between the seconds and fractions of seconds will be maped to '**·**'; as widows uses '**:**' specially.

      * under windows the this will always be the case, so you don't need it there.

[Top of Document](#table-of-contents)

### sc restore db

```bash
sc restore db --help

Usage:
  sc restore db [<restore-from>]
```

[Top of Document](#table-of-contents)

### sc menu restore db

Restore the db using a menu to make it easy to choose the db backup from the ones available in the configuration directory. 

```bash
sc menu restore db --help

Usage:
  sc menu restore db [<message>]  [-c|--color|--colour] [-s|--syntax]
```

[Top of Document](#table-of-contents)

### sc list db backups

List all the backups availble 

```bash
sc list db backups --help

Usage:                                                                                                                                                
  sc list db backups [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]          

06:05:06 θ73° grizzlysmit@pern:~/Projects/raku/syscon main(+16/-3) 2s ± sc list db backups --syntax 

Permissions Size   User        Group       Date Modified                    Backup                                      
========================================================================================================================
.rw-rw-r--  119.0B grizzlysmit grizzlysmit 2023-12-22T08:12:27.099044+11:00 hosts.h_ts.2023-11-05                       
.rw-rw-r--  819.0B grizzlysmit grizzlysmit 2023-12-22T05:55:00.266606+11:00 hosts.h_ts.2023-11-06                       
.rw-rw-r--  817.0B grizzlysmit grizzlysmit 2023-12-22T05:55:11.410923+11:00 hosts.h_ts.2023-11-07                       
.rw-rw-r--  817.0B grizzlysmit grizzlysmit 2023-12-22T05:55:19.519153+11:00 hosts.h_ts.2023-11-08                       
.rw-rw-r--  819.0B grizzlysmit grizzlysmit 2023-12-22T05:56:07.548518+11:00 hosts.h_ts.2023-11-09                       
.rw-rw-r--  1.1KiB grizzlysmit grizzlysmit 2023-12-22T05:56:07.564518+11:00 hosts.h_ts.2023-11-10                       
.rw-rw-r--  1.6KiB grizzlysmit grizzlysmit 2023-11-23T23:09:31.135082+11:00 hosts.h_ts.2023-11-11                       
.rw-rw-r--  1.7KiB grizzlysmit grizzlysmit 2023-11-23T23:09:31.135082+11:00 hosts.h_ts.2023-11-12                       
.rw-rw-r--  2.3KiB grizzlysmit grizzlysmit 2023-11-23T23:09:31.135082+11:00 hosts.h_ts.2023-11-16                       
.rw-rw-r--  3.1KiB grizzlysmit grizzlysmit 2023-11-23T23:09:31.135082+11:00 hosts.h_ts.2023-11-22T21:06:40.298049+11:00 
.rw-rw-r--  3.1KiB grizzlysmit grizzlysmit 2023-11-23T23:09:31.135082+11:00 hosts.h_ts.2023-11-22T21:12:33.993733+11:00 
.rw-rw-r--  1.9KiB grizzlysmit grizzlysmit 2023-12-22T01:36:57.851869+11:00 hosts.h_ts.2023-12-22T01:37:34.850866+11:00 
.rw-rw-r--  2.0KiB grizzlysmit grizzlysmit 2023-12-22T05:09:41.221386+11:00 hosts.h_ts.2023-12-22T05:10:18.222608+11:00 
.rw-rw-r--  2.0KiB grizzlysmit grizzlysmit 2023-12-22T05:25:47.976861+11:00 hosts.h_ts.2023-12-22T05:26:24.971369+11:00 
.rw-rw-r--  2.1KiB grizzlysmit grizzlysmit 2023-12-25T13:35:13.848452+11:00 hosts.h_ts.2023-12-25T13:35:50.847566+11:00 
.rw-rw-r--  2.2KiB grizzlysmit grizzlysmit 2023-12-25T13:38:11.509524+11:00 hosts.h_ts.2023-12-25T13:38:48.509083+11:00 
.rw-rw-r--  2.5KiB grizzlysmit grizzlysmit 2023-12-26T04:43:12.073269+11:00 hosts.h_ts.2023-12-26T04:43:49.073219+11:00 
.rw-rw-r--  3.2KiB grizzlysmit grizzlysmit 2023-12-28T07:37:44.880821+11:00 hosts.h_ts.2023-12-28T07:38:21.875751+11:00 
.rw-rw-r--  2.8KiB grizzlysmit grizzlysmit 2023-12-28T08:40:10.167277+11:00 hosts.h_ts.2023-12-28T08:40:47.166191+11:00 
.rw-rw-r--  2.9KiB grizzlysmit grizzlysmit 2023-12-28T22:08:43.954589+11:00 hosts.h_ts.2023-12-28T22:09:20.949994+11:00 
.rw-rw-r--  2.9KiB grizzlysmit grizzlysmit 2023-12-30T08:25:15.130101+11:00 hosts.h_ts.2023-12-30T08:25:52.126298+11:00 
.rw-rw-r--  2.9KiB grizzlysmit grizzlysmit 2023-12-31T16:37:17.175992+11:00 hosts.h_ts.2023-12-31T16:37:54.163543+11:00 
.rw-rw-r--  2.9KiB grizzlysmit grizzlysmit 2024-01-01T11:50:09.886243+11:00 hosts.h_ts.2024-01-01T11:50:46.878720+11:00 
.rw-rw-r--  2.9KiB grizzlysmit grizzlysmit 2024-01-02T23:56:12.089118+11:00 hosts.h_ts.2024-01-02T23:56:48.967417+11:00 
========================================================================================================================
```

[See list-db-backups(…) for the implementation](#list-db-backups)

[Top of Document](#table-of-contents)

The Syscon library
==================

**`$config`**
-------------

```raku
# config files
constant $config is export = "$home/.local/share/syscon";
```

[Top of Document](#table-of-contents)

### say-list-keys(…)

```raku
sub make-array( --> Array) is export 

sub say-list-keys(Str $prefix,
                  Bool:D $colour,
                  Bool:D $syntax,
                  Regex:D $pattern,
                  Int:D $page-length --> Bool:D) is export
```

[For and example of use see sc list keys](#sc-list-keys)

[Top of Document](#table-of-contents)

### list-by-all

```raku
sub list-by-all(Str:D $prefix,
                Bool:D $colour,
                Bool:D $syntax,
                Int:D $page-length,
                Regex:D $pattern --> Bool:D) is export {
```

[For usage see sc list all](#sc-list-all)

[Top of Document](#table-of-contents)

### list-db-backups(…)

```raku
sub list-db-backups(Str:D $prefix,
                    Bool:D $colour is copy,
                    Bool:D $syntax,
                    Regex:D $pattern,
                    Int:D $page-length --> Bool:D) is export
```

[See sc list db backups for usage](#sc-list-db-backups)

[Top of Document](#table-of-contents)

### ssh(…)

```raku
sub ssh(Str:D $key --> Bool) is export
```

[See sc ssh](#sc-ssh)

[Top of Document](#table-of-contents)

### ping(…)

```raku
sub ping(Str:D $key --> Bool) is export
```

[See sc ping](#sc-ping)

[Top of Document](#table-of-contents)

### _get(…)

```raku
multi sub _get('home', Str:D $key,
                Bool :r(:$recursive) = False,
                Str:D :$to = '.',
                *@args --> Bool) is export
```

[See sc get home](#sc-get-home)

[Top of Document](#table-of-contents)

### _put(…)

```raku
multi sub _put('home', Str:D $key,
                Bool :r(:$recursive) = False,
                Str:D :$to = '',
                *@args --> Bool) is export
```

[See sc put home](#sc-put-home)

[Top of Document](#table-of-contents)

