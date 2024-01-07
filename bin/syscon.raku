#!/usr/bin/env raku
use v6;
use ECMA262Regex;

my %*SUB-MAIN-OPTS;
%*SUB-MAIN-OPTS«named-anywhere» = True;
#%*SUB-MAIN-OPTS<bundling>       = True;

=begin pod

=head1 Syscon,  sc

=begin head2

Table of  Contents

=end head2

=item1 L<NAME|#name>
=item1 L<AUTHOR|#author>
=item1 L<VERSION|#version>
=item1 L<TITLE|#title>
=item1 L<SUBTITLE|#subtitle>
=item1 L<COPYRIGHT|#copyright>
=item1 L<Introduction|#introduction>
=item2 L<Motivations|#motivations>
=item1 L<USAGE|#usage>
=item2 L<The actual work horses of the library|#the-actual-work-horses-of-the-library>
=item3 L<sc ssh|#sc-ssh>
=item3 L<sc ping|#sc-ping>
=item3 L<sc get home|#sc-get-home>
=item3 L<sc put home|#sc-put-home>
=item2 L<Utility functions|#utility-functions>
=item3 L<sc edit configs|#sc-edit-configs>
=item3 L<sc list keys|#sc-list-keys>
=item3 L<sc list by all|#sc-list-by-all>
=item3 L<sc list trash|#sc-list-trash>
=item3 L<sc trash|#sc-trash>
=item3 L<sc empty trash|#sc-empty-trash>
=item3 L<sc undelete|#sc-undelete>
=item3 L<sc stats|#sc-stats>
=item3 L<sc statistics|#sc-statistics>
=item3 L<sc add|#sc-add>
=item3 L<sc delete|#sc-delete>
=item3 L<sc del|#sc-del>
=item3 L<sc comment|#sc-comment>
=item3 L<backup db|#backup-db>
=item3 L<sc restore db|#sc-restore-db>
=item3 L<sc menu restore db|#sc-menu-restore-db>
=item3 L<USAGE|#fred>
=item3 L<USAGE|#wilma>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item2 L<module Syscon|#the-syscon-library>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<USAGE|#usage>
=item3 L<ssh(…)|#ssh>
=item3 L<ping(…)|#ping>
=item3 L<_get(…)|#_get> or L<on raku.land _get|#-get>
=item3 L<_put|#usage> or L<on raku.land _get|#-put>

=NAME syscon, sc
=AUTHOR Francis Grizzly Smit (grizzly@smit.id.au)
=VERSION v0.1.18
=TITLE syscon, sc
=SUBTITLE A module B<C<Syscon>> and a program B<C<syscon>> or B<C<sc>> for short, which keeps tarck of assorted servers and helps to connect to them.

=COPYRIGHT
LGPL V3.0+ L<LICENSE|/LICENSE>

=head1 Introduction

A module B<C<Syscon>> and a program B<C<syscon>> or B<C<sc>> for short, which keeps tarck of assorted
servers and helps to connect to them.

L<Top of Document|#table-of-contents>

=head2 Motivations

I have to keep track of many servers (> 100) but who can remember all the host names, and ports??
That is where this app comes in I can connect to a server by ssh by.

=begin code :lang<bash>

$ syscon.raku ssh <key>

=end code

or for short

=begin code :lang<bash>

$ sc ssh <key>

=end code

Equally you can use

=begin code :lang<bash>

$ sc put home <key> <files> ……

=end code

To run 

=begin code :lang<bash>

$ scp -P $port <files> …… $host:

=end code

=item1 Where 
=item2 B<C<$host>> is generally something like B<C<username@example.com>>
=item2 B<C<$port>> is a port number.
=item2 B<key> is the key to retrieve the host and port form the server.
=item3 It's put home because I may add put <other-place> at a later date.

L<Top of Document|#table-of-contents>

This is the app, you can find the modules docs L<here|/docs/Syscon.md>

=end pod


use Gzz::Text::Utils;
#use Syntax::Highlighters;
use GUI::Editors;
use Usage::Utils;
use Syscon;

=begin pod

=head3 USAGE

=begin code :lang<bash>

sc --help

Usage:                                                                                                                                                
  sc ssh <key>
  sc ping <key>
  sc get home <key>  [<args> ...] [-r|--recursive] [-t|--to=<Str>]
  sc put home <key>  [<args> ...] [-r|--recursive] [-t|--to=<Str>]
  sc edit configs
  sc list keys  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
  sc list by all  [<prefix>]  [-c|--color|--colour] [-s|--syntax] [-l|--page-length[=Int]] [-p|--pattern=<Str>] [-e|--ecma-pattern=<Str>]
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
 
=end code

!L<image not available here go to the github page|/docs/images/usage.png>

L<Top of Document|#table-of-contents>

=end pod

#`«««
    ############################################
    #                                          #
    #   The actual work horses of the library  #
    #                                          #
    ############################################
#»»»

=begin pod

=head2 The actual work horses of the library

=head3 sc ssh

Runs

=begin code :lang<bash>

ssh -p $port $host

=end code

by the B<C<ssh(…)>> function defined in B<Syscon.rakumod>.

=begin code :lang<bash>

22:22:06 θ76° grizzlysmit@pern:~ $ sc  ssh rak
ssh -p 22 rakbat.local
Welcome to Ubuntu 23.10 (GNU/Linux 6.5.0-14-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

0 updates can be applied immediately.



Last login: Tue Jan  2 23:48:56 2024 from 192.168.188.11
06:55:31 grizzlysmit@rakbat:~ $ 

=end code

!L<image not available here go to the github page|/docs/images/sc-ssh.png>

Implemented as L<B<C<ssh(…)>>|#ssh> in L<module Syscon|#the-syscon-library>.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('ssh', Str:D $key --> int){
    if ssh($key) {
        return 0;
    } else {
        return 1;
    }
}

=begin pod

=head3 sc ping

Runs

=begin code :lang<bash>

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


=end code

=item1 Where
=item2 B<C<$key>> a key in the db.


!L<image not available here go to the github page|/docs/images/ping.png>


Implemented as L<B<C<ping(…)>>|#ping> in L<module Syscon|#the-syscon-library>.

=begin code :lang<raku>

multi sub MAIN('ping', Str:D $key --> int){
    if ping($key) {
        return 0;
    } else {
        return 1;
    }
}

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('ping', Str:D $key --> int){
    if ping($key) {
        return 0;
    } else {
        return 1;
    }
}

=begin pod

=head3 sc get home

Get some files on the remote system and deposit them here (in the directory the user is currently in).

=begin code :lang<bash>

$ sc get home $key --to=$to --recursive $files-on-remote-system……

=end code

=item1 Where
=item2 B<C<$key>>                       The key of the host to get files from.
=item2 B<C<$to>>                        The place to put the files defaults to B<C<.>> or here.
=item2 B<C<--recursive>>                sets the recursive flag so the files will be copied recursively, allowing a whole file sub tree to be copied.
=item2 B<C<$files-on-remote-system……>>  A list of files on the remote system to copy can be anywhere on the remote system.

e.g.

=begin code :lang<bash>

$ sc get home rak --to=scratch .bashrc /etc/hosts 
scp -P 22 rakbat.local:.bashrc .
.bashrc                   100%   11KB   6.9MB/s   00:00
scp -P 22 rakbat.local:/etc/hosts .
hosts                     100%  313   228.8KB/s   00:00

=end code

!L<image not available here go to the github page|/docs/images/sc-get-home.png>


Using the B<_get> function defined in B<Syscon.rakumod> L<See B<C<_get(…)>>|#_get> or L<on raku.land B<C<_get(…)>>|#-get>.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('get', 'home', Str:D $key, Bool :r(:$recursive) = False, Str:D :t(:$to) = '.', *@args --> int){
    if _get('home', $key, :$recursive, :$to, |@args) {
        return 0;
    } else {
        return 1;
    }
}

=begin pod

=head3 sc put home

=begin code :lang<bash>

$ sc put home $key --to=$to --recursive $files……

=end code

=item1 Where
=item2 B<C<$key>> is as always the key to identify the host in question.
=item2 B<C<$to>> is the place to put the files on the rmote system.
=item2 B<C<--recursive>> sets the recursive flag so the files will be copied recursively, allowing a whole file sub tree to be copied.
=item2 B<C<$files>>…… is a list of files to copy to the remote server.

=begin code :lang<bash>

sc put home kil --to=tmp scratch/bug.raku  docs/Syscon.1 
scp -P 22 scratch/bug.raku docs/Syscon.1 grizzlysmit@killashandra.local:tmp
bug.raku                                           100% 3303   557.3KB/s   00:00
Syscon.1                                           100%  485     1.0MB/s   00:00

=end code

!L<image not available here go to the github page|/docs/images/sc-put-home.png>

Implemented as

=begin code :lang<raku>

multi sub MAIN('put', 'home', Str:D $key, Bool :r(:$recursive) = False, *@args --> int){
    if _put('home', $key, :$recursive, |@args) {
        return 0;
    } else {
        return 1;
    }
}

=end code

=item1 Where
=begin item2 

B<C<multi sub _put('home', Str:D $key, Bool :r(:$recursive) = False, Str:D :$to = '', *@args --> Bool) is export>>
is a function in B<Sysycon.rakumod> See L<B<C<_put(…)>>|#_put> or L<on raku.land B<C<_put(…)>>|#-put>.

=end item2

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('put', 'home', Str:D $key, Bool :r(:$recursive) = False, Str:D :t(:$to) = '', *@args --> int){
    if _put('home', $key, :$recursive, :$to, |@args) {
        return 0;
    } else {
        return 1;
    }
}

#`«««
    ##################################
    #********************************#
    #*                              *#
    #*      Utility functions       *#
    #*                              *#
    #********************************#
    ##################################
#»»»

=begin pod

=head2 Utility functions

=head3 sc edit configs

=begin code :lang<bash>

$ sc edit configs

=end code

Implemented by the B<C<edit-configs>> function in the B<GUI::Editors.rakumod> module.
This open your configuration files in your preferred GUI editor, if you have one, if 
you don't have one of those setup it will try for a good substitute, failing
that it will Fail and print an error message. 

Do not use this it's for experts only, instead use the B<set-*(…)> functions below.

=begin code :lang<raku>

multi sub MAIN('edit', 'configs') returns Int {
   if edit-configs() {
       exit 0;
   } else {
       exit 1;
   } 
}

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('edit', 'configs') returns Int {
   if edit-configs() {
       exit 0;
   } else {
       exit 1;
   } 
}

=begin pod

=head3 sc list keys 

=begin code :lang<bash>

$ sc list keys --help

=end code

!L<image not available here go to the github page|/docs/images/sc-list-keys.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('list', 'keys', Str $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 50,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if say-list-keys($prefix, $colour, $syntax, $_pattern, $page-length) {
       exit 0;
    } else {
       exit 1;
    } 
}

=begin pod

=head3 sc list by all

=begin code :lang<bash>

sc list by all --help

=end code

!L<image not available here go to the github page|/docs/images/sc-list-by-all.png>

=begin code :lang<bash>

sc list by all

=end code

!L<image not available here go to the github page|/docs/images/sc-list-by-all-pattern.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('list', 'by', 'all', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False,
                    Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str,
                                                                Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-by-all($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
    } else {
       exit 1;
    } 
} #`««« multi sub MAIN('list', 'by', 'all', Str:D $prefix = '', Bool:D :c(:color(:$colour)) = False,
                    Bool:D :s(:$syntax) = False, Int:D :l(:$page-length) = 50, Str :p(:$pattern) = Str,
                                                                Str :e(:$ecma-pattern) = Str) returns Int »»»

=begin pod

=head3 sc list trash

=begin code :lang<bash>

sc list trash --help

=end code

!L<image not available here go to the github page|/docs/images/sc-list-trash--help.png>

=begin code :lang<bash>

sc list trash --help

=end code

!L<image not available here go to the github page|/docs/images/sc-list-trash.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('list', 'trash', Str:D $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
   if list-commented($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
   } else {
       exit 1;
   } 
}

=begin pod

=head3 sc trash

=begin code :lang<raku>

sc trash --help

=end code

!L<image not available here go to the github page|/docs/images/sc-trash--help.png>

=begin code :lang<raku>

sc trash

=end code

!L<image not available here go to the github page|/docs/images/sc-trash.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('trash', *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, True) {
            $result++;
        } 
    }
    exit $result;
}

=begin pod

=head3 sc empty trash

=begin code :lang<bash>

sc empty trash --help

=end code

!L<image not available here go to the github page|/docs/images/sc-empty-trash.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('empty', 'trash') returns Int {
   if empty-trash() {
       exit 0;
   } else {
       exit 1;
   } 
}

=begin pod

=head3 sc undelete

=begin code :lang<bash>

sc undelete --help

=end code

!L<image not available here go to the github page|/docs/images/sc-undelete.png>

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('undelete', *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless undelete($key) {
            $result++;
        } 
    }
    exit $result;
}

=begin pod

=head3 sc stats

=begin code :lang<bash>

sc stats

=end code

!L<image not available here go to the github page|/docs/images/sc-stats.png>

=end pod

multi sub MAIN('stats', Str:D $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if stats($prefix, $colour, $syntax, $_pattern) {
        exit 0;
    } else {
        exit 1;
    } 
} # multi sub MAIN('stats', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int #

=begin pod

=head3 sc statistics

An alias of stats see above L<sc stats|#sc-stats>.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('statistics', Str:D $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if stats($prefix, $colour, $syntax, $_pattern) {
        exit 0;
    } else {
        exit 1;
    } 
} # multi sub MAIN('statistics', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int #

=begin pod

=head3 sc add

=begin code :lang<bash>

sc add <key> <host> [<port>]  [-s|--set|--force] [-c|--comment=<Str>] 

=end code

=item1 Where
=item2 B«C«<key>»» is a unused key unless you use one of B<C<-s|--set|--force>> in which case it will overwrite the old value.
=item2 B«C«<host>»» is a host spec of the form B<username@dns-address-or-host-name>.
=item2 B«C«<port>»» is a port number, if not present defaults to B<22>.
=item2 If B<-s>, B<--set> or B<--force> is present you can overwrite existing entries use with care.
=item2 If B<-c> or B<--comment> are present then B«C«<Str>»» should be a comment string to go with the entry.
=begin item3
Example use.

!L<sc add ex grizzlysmit@example.com 344 --comment="an example host"|/docs/images/sc-add.png>

=end item3

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('add', Str:D $key, Str:D $host,
                PortVal:D $port = 22,
                Bool:D :s(:set(:$force)) = False,
                Str :c(:$comment) = Str) returns Int {
   if add-host($key, $host, $port, $force, $comment) {
       exit 0;
   } else {
       exit 1;
   }
}

=begin pod

=head3 sc delete

A command to delete a row in the db i.e. a key and details, 
by default it just trashes the key but if B<-d>,  B<--delete> or B<--do-not-trash> is present 
it will really delete. 

=begin code :lang<bash>

sc delete --help
                                                                                                                                                      
Usage:                                                                                                                                                
  sc delete [<keys> ...] [-d|--delete|--do-not-trash]                                          

=end code

=item1 Where
=item2 B«C«[<keys> ...]»»                  is a optional list of keys if none are provided then the command does nothing 
=item2 B<C<[-d|--delete|--do-not-trash]>>  is a flag to really delete, not trash them see L<see|#sc-trash>.

=head3 sc del 

An alias for delete 


=begin code :lang<bash>

 sc del --help
                                                                                                                                                      
Usage:                                                                                                                                                
  sc delete [<keys> ...] [-d|--delete|--do-not-trash]                                                                                                 
  sc del [<keys> ...] [-d|--delete|--do-not-trash]

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('delete', Bool:D :d(:delete(:$do-not-trash)) = False, *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, !$do-not-trash) {
            $result++;
        } 
    }
    exit $result;
}

multi sub MAIN('del', Bool:D :d(:delete(:$do-not-trash)) = False, *@keys) returns Int {
    my Int:D $result = 0;
    for @keys -> $key {
        unless delete-key($key, !$do-not-trash) {
            $result++;
        } 
    }
    exit $result;
}

=begin pod

=head3 sc comment

Add or set  a comment to a db entry. 

=begin code :lang<bash>

sc comment --help
                                                                                                                                                      
Usage:                                                                                                                                                
  sc comment <key> <comment>                                                                                                                          
=end code

=item1 Where
=item2 B«C«<key>»»      An existing key in the db.
=item2 B«C«<comment>»»  The comment to add.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('comment', Str:D $key, Str:D $comment) returns Int {
    if add-comment($key, $comment) {
        exit 0;
    } else {
        exit 1;
    } 
}

=begin pod

=head3 sc alias

=begin code :lang<bash>

sc alias --help
                                                                                                                                                      
Usage:                                                                                                                                                
  sc alias <key> <target>  [-s|--set|--force] [-d|--really-force|--overwrite-hosts] [-c|--comment=<Str>]

=end code

=item1 Where
=item2 B«C«<key>»» is a new key to add or an exiting one to overwrite if you use B<-s>, B<--set> or B<--force>.
=item3 B<NB:> B<-s>, B<--set> or B<--force> only work for B<aliases> to overwrite B<hosts> use B<-d>, B<--really-force> or B<--overwrite-hosts>.
=item2 B«C«<target>»» Either a existing host or alias, it is an error if B«C«<target>»» does not exist.
=item2 B<-s>, B<--set> or B<--force> mean overwrite any existing B«C«<key>»» if it is an alias.
=item2 B<-d>, B<--really-force> or B<--overwrite-hosts> means overwrite anything regardless, use with care.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('alias', Str:D $key, Str:D $target,
                                Bool:D :s(:set(:$force)) = False,
                                Bool:D :d(:really-force(:$overwrite-hosts)) = False,
                                Str :c(:$comment) = Str) returns Int {
   if add-alias($key, $target, $force, $overwrite-hosts, $comment) {
       exit 0;
   } else {
       exit 1;
   } 
}

=begin pod

=head3 backup db

Backup the file which is the db for this little app, I could use a I<real> db but as it's just one simple table, I don't need that.

=begin code :lang<bash>

 sc backup db --help
                                                                                                                                                      
Usage:
  sc backup db  [-w|--win-format|--use-windows-formating]

=end code

=item1 Where
=begin item2

B<-w>, B<--win-format> or B<--use-windows-formating> means that the 'B<:>' in the date time
will be replaced with 'B<.>' and the 'B<.>' the decimal point between the seconds and fractions 
of seconds will be maped to 'B<·>'; as widows uses 'B<:>' specially.

=end item2
=item3 under windows the this will always be the case, so you don't need it there.

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('backup', 'db', Bool:D :w(:win-format(:$use-windows-formating)) = False --> Bool) {
    if backup-db-file($use-windows-formating) {
        exit 0;
    } else {
        die "Error: backup failed!!!";
    }
}

=begin pod

=head3 sc restore db

=begin code :lang< bash>

sc restore db --help

Usage:
  sc restore db [<restore-from>]

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('restore', 'db', Str $restore-from = Str --> Bool) {
    my IO::Path $_restore-from;
    with $restore-from {
        $_restore-from = $restore-from.IO;
    }
    if restore-db-file($_restore-from) {
        exit 0;
    } else {
        die "Error: restore backup failed!!!";
    }
}

=begin pod

=head3 sc menu restore db

Restore the db using a menu to make it easy to choose the db
backup from the ones available in the configuration directory. 

=begin code :lang<bash>

sc menu restore db --help

Usage:
  sc menu restore db [<message>]  [-c|--color|--colour] [-s|--syntax]

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub MAIN('menu', 'restore', 'db',
                Str:D $message = '',
                Bool:D :c(:color(:$colour)) = False,
                Bool:D :s(:$syntax) = False) returns Int {
   if backups-menu-restore-db($colour, $syntax, $message) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('list', 'db', 'backups', Str:D $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-db-backups($prefix, $colour, $syntax, $_pattern, $page-length) {
        exit 0;
    } else {
        exit 1;
    } 
}

#`«««
    ##################################
    #********************************#
    #*                              *#
    #*       Editor functions       *#
    #*                              *#
    #********************************#
    ##################################
#»»»

multi sub MAIN('list', 'editors', Str:D :f(:$prefix) = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
   if list-editors($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('editors', 'stats', Str:D $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
   if editors-stats($prefix, $colour, $syntax, $page-length, $_pattern) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('list', 'editors', 'backups', Str:D $prefix = '',
                               Bool:D :c(:color(:$colour)) = False,
                               Bool:D :s(:$syntax) = False,
                               Int:D :l(:$page-length) = 30,
                               Str :p(:$pattern) = Str,
                               Str :e(:$ecma-pattern) = Str) returns Int {
    my Regex $_pattern;
    with $pattern {
        $_pattern = rx:i/ <$pattern> /;
    } orwith $ecma-pattern {
        $_pattern = ECMA262Regex.compile("^$ecma-pattern\$");
    } else {
        $_pattern = rx:i/^ .* $/;
    }
    if list-editors-backups($prefix, $colour, $syntax, $_pattern, $page-length) {
        exit 0;
    } else {
        exit 1;
    } 
}

multi sub MAIN('backup', 'editors', Bool:D :w(:$use-windows-formatting) = False) returns Int {
   if backup-editors($use-windows-formatting) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('restore', 'editors', Str:D $restore-from) returns Int {
   if restore-editors($restore-from.IO) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('set', 'editor', Str:D $editor, Str $comment = Str) returns Int {
   if set-editor($editor, $comment) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('set', 'override', 'GUI_EDITOR', Bool:D $value, Str $comment = Str) returns Int {
   if set-override-GUI_EDITOR($value, $comment) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('menu', 'restore', 'editors', Str:D $message = '', Bool:D :c(:color(:$colour)) = False, Bool:D :s(:$syntax) = False) returns Int {
   if backups-menu-restore-editors($colour, $syntax, $message) {
       exit 0;
   } else {
       exit 1;
   } 
}

#`«««
    #########################################################
    #                                                       #
    #   vanity functions no real point in their existance   #
    #                                                       #
    #########################################################
#»»»

multi sub MAIN('tidy', 'file') returns Int {
   if tidy-file() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('sort', 'file') returns Int {
   if sort-file() {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('show', 'file', Bool:D :c(:color(:$colour)) = False) returns Int {
   if show-file($colour) {
       exit 0;
   } else {
       exit 1;
   } 
}

multi sub MAIN('help', Bool:D :n(:nocolor(:$nocolour)) = False, *%named-args, *@args) returns Int {
   my @_args is Array[Str] = |@args[1 .. *];
   #say @_args.shift;
   say-coloured($*USAGE, $nocolour, |%named-args, |@_args);
   exit 0;
}

#`«««
multi sub MAIN('test') returns Int {
   test();
   exit 0;
}
#»»»

#`«««
    ***********************************************************
    *                                                         *
    *                       USAGE Stuff                       *
    *                                                         *
    ***********************************************************
#»»»

sub USAGE(Bool:D :n(:nocolor(:$nocolour)) = False, *%named-args, *@args --> Int) {
    say-coloured($*USAGE, False, %named-args, @args);
    exit 0;
}

multi sub GENERATE-USAGE(&main, |capture --> Int) {
    my @capture = |(capture.list);
    my @_capture;
    if @capture && @capture[0] eq 'help' {
        @_capture = |@capture[1 .. *];
    } else {
        @_capture = |@capture;
    }
    my %capture = |(capture.hash);
    if %capture«nocolour» || %capture«nocolor» || %capture«n» {
        say-coloured($*USAGE, True, |%capture, |@_capture);
    } else {
        #dd @capture;
        say-coloured($*USAGE, False, |%capture, |@_capture);
        #&*GENERATE-USAGE(&main, |capture)
    }
    exit 0;
}
