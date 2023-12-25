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

LGPL V3.0+ [LICENSE](https://github.com/grizzlysmit/syscon/blob/main/LICENSE)

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

This is the app, you can find the modules docs [here](https://github.com/grizzlysmit/syscon)

### USAGE

```bash
$ sc --help
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/usage.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/usage.png)

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

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-ssh.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-ssh.png)

[Top of Document](#table-of-contents)

### sc ping

Runs

```bash
$ sc ping $server
```

  * Where

    * **`$server`** is the domain part of the host value i.e. with the **`username@`** removed.

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/ping.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/ping.png)

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

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-get-home.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-get-home.png)

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

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-put-home.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-put-home.png)

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

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-keys.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-keys.png)

[Top of Document](#table-of-contents)

### sc list by all

```bash
sc list by all --help
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-by-all.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-by-all.png)

```bash
sc list by all
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-by-all-pattern.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-by-all-pattern.png)

### sc list trash

```bash
sc list trash --help
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-trash--help.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-trash--help.png)

```bash
sc list trash --help
```

![https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-trash.png](https://github.com/grizzlysmit/syscon/blob/main/docs/images/sc-list-trash.png)

