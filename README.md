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

      * [sc list by all](#sc-list-by-all)

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

      * [USAGE](#usage)

NAME
====

syscon 

AUTHOR
======

Francis Grizzly Smit (grizzly@smit.id.au)

VERSION
=======

v0.1.18

TITLE
=====

syscon

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
$ sc --help
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

```raku
multi sub MAIN('ssh', Str:D $key --> int){
    if ssh($key) {
        return 0;
    } else {
        return 1;
    }
}
```

![image not available here go to the github page](/docs/images/sc-ssh.png)

[Top of Document](#table-of-contents)

### sc ping

Runs

```bash
$ sc ping $key
```

  * Where

    * **`$key`** a key in the db.

![image not available here go to the github page](/docs/images/ping.png)

by the **`sc ping $key`**

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
$ sc get home $key $files-on-remote-system……
```

![image not available here go to the github page](/docs/images/sc-get-home.png)

Defined as 

```raku
multi sub MAIN('get', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _get('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}
```

Using the **`_get(…)`** function defined in **Syscon.rakumod**.

[Top of Document](#table-of-contents)

### sc put home

```bash
$ sc put home $key $files……
```

  * Where

    * **`$key`** is as always the key to identify the host in question.

    * **`$files`**…… is a list of files to copy to the remote server.

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

    * **`multi sub _put('home', Str:D $key, Bool :r(:$recursive) = False, *@args --` Bool) is export**> is a function in **Sysycon.rakumod**

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
```

![image not available here go to the github page](/docs/images/sc-list-keys.png)

[Top of Document](#table-of-contents)

### sc list by all

```bash
sc list by all --help
```

![image not available here go to the github page](/docs/images/sc-list-by-all.png)

```bash
sc list by all
```

![image not available here go to the github page](/docs/images/sc-list-by-all-pattern.png)

[Top of Document](#table-of-contents)

### sc list trash

```bash
sc list trash --help
```

![image not available here go to the github page](/docs/images/sc-list-trash--help.png)

```bash
sc list trash --help
```

![image not available here go to the github page](/docs/images/sc-list-trash.png)

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

an alias for delete 

### sc del 

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

