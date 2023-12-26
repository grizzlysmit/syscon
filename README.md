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

![`sc --help --nocolour Usage: sc ssh <key> sc ping <key> sc get home <key> [<args> ...] [-r|--recursive] sc put home <key> [<args> ...] [-r|--recursive] sc edit configs sc list keys [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc list by all [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc list trash [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc trash [<keys> ...] sc empty trash sc undelete [<keys> ...] sc stats [-c|--color|--colour] [-s|--syntax] sc statistics [-c|--color|--colour] [-s|--syntax] sc add <key> <host> [<port>] [-s|--set|--force] [-c|--comment=<Str>] sc delete [<keys> ...] [-d|--delete|--do-not-trash] sc del [<keys> ...] [-d|--delete|--do-not-trash] sc comment <key> <comment> sc alias <key> <target> [-s|--set|--force] [-d|--really-force|--overwrite-hosts] [-c|--comment=<Str>] sc backup db [-w|--win-format|--use-windows-formating] sc restore db [<restore-from>] sc list db backups [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc list editors [-f|--prefix=<Str>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc editors stats [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc list editors backups [<prefix>] [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>] sc backup editors [-w|--use-windows-formatting] sc restore editors <restore-from> sc set editor <editor> [<comment>] sc set override GUI_EDITOR <value> [<comment>] sc menu restore editors [<message>] [-c|--color|--colour] [-s|--syntax] sc tidy file sc sort file sc show file [-c|--color|--colour] sc help [<args> ...] [-n|--nocolor|--nocolour] [--<named-args>=...]`](/docs/images/usage.png)

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

![`sc ssh rak ssh -p 22 rakbat.local Welcome to Ubuntu 23.10 (GNU/Linux 6.5.0-14-generic x86_64) * Documentation: https://help.ubuntu.com * Management: https://landscape.canonical.com * Support: https://ubuntu.com/advantage 0 updates can be applied immediately. Last login: Thu Dec 21 07:43:01 2023 from 192.168.188.15`](/docs/images/sc-ssh.png)

[Top of Document](#table-of-contents)

### sc ping

Runs

```bash
$ sc ping $key
```

  * Where

    * **`$key`** a key in the db.

![`sc ping rak ping rakbat.local PING rakbat.local (192.168.188.13) 56(84) bytes of data. 64 bytes from rakbat.local (192.168.188.13): icmp_seq=1 ttl=64 time=0.855 ms 64 bytes from rakbat.local (192.168.188.13): icmp_seq=2 ttl=64 time=0.256 ms 64 bytes from rakbat.local (192.168.188.13): icmp_seq=3 ttl=64 time=0.609 ms 64 bytes from rakbat.local (192.168.188.13): icmp_seq=4 ttl=64 time=0.568 ms 64 bytes from rakbat.local (192.168.188.13): icmp_seq=5 ttl=64 time=0.518 ms 64 bytes from rakbat.local (192.168.188.13): icmp_seq=6 ttl=64 time=0.493 ms 64 bytes from rakbat.local (192.168.188.13): icmp_seq=7 ttl=64 time=0.288 ms ^C --- rakbat.local ping statistics --- 7 packets transmitted, 7 received, 0% packet loss, time 6136ms rtt min/avg/max/mdev = 0.256/0.512/0.855/0.187 ms`](/docs/images/ping.png)

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

![/docs/images/sc-get-home.png](/docs/images/sc-get-home.png)

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

![/docs/images/sc-put-home.png](/docs/images/sc-put-home.png)

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

![/docs/images/sc-list-keys.png](/docs/images/sc-list-keys.png)

[Top of Document](#table-of-contents)

### sc list by all

```bash
sc list by all --help
```

![/docs/images/sc-list-by-all.png](/docs/images/sc-list-by-all.png)

```bash
sc list by all
```

![/docs/images/sc-list-by-all-pattern.png](/docs/images/sc-list-by-all-pattern.png)

[Top of Document](#table-of-contents)

### sc list trash

```bash
sc list trash --help
```

![/docs/images/sc-list-trash--help.png](/docs/images/sc-list-trash--help.png)

```bash
sc list trash --help
```

![/docs/images/sc-list-trash.png](/docs/images/sc-list-trash.png)

[Top of Document](#table-of-contents)

### sc trash

```raku
sc trash --help
```

![/docs/images/sc-trash--help.png](/docs/images/sc-trash--help.png)

```raku
sc trash
```

![/docs/images/sc-trash.png](/docs/images/sc-trash.png)

[Top of Document](#table-of-contents)

### sc empty trash

```bash
sc empty trash --help
```

![/docs/images/sc-empty-trash.png](/docs/images/sc-empty-trash.png)

[Top of Document](#table-of-contents)

### sc undelete

```bash
sc undelete --help
```

![/docs/images/sc-undelete.png](/docs/images/sc-undelete.png)

[Top of Document](#table-of-contents)

