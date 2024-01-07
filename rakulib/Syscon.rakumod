unit module Syscon:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

use Terminal::ANSI::OO :t;
use Terminal::Width;
use Terminal::WCWidth;
use Gzz::Text::Utils;
use Syntax::Highlighters;
use GUI::Editors;
use Usage::Utils;
use Display::Listings;
use File::Utils;
#use Grammar::Debugger;
#use Grammar::Tracer;
#use trace;

# the home dir #
constant $home is export = %*ENV<HOME>.Str();

=begin pod


=head1 The Syscon library

=head2 B<C<$config>>

=begin code :lang<raku>

# config files
constant $config is export = "$home/.local/share/syscon";

=end code

L<Top of Document|#table-of-contents>

=end pod

# config files
constant $config is export = "$home/.local/share/syscon";

if $config.IO !~~ :d {
    $config.IO.mkdir();
}

# The config files to test for #
my Str @host-config-files = |qw{hosts.h_ts};

my Str $client-config;

sub generate-configs(Str:D $file, Str:D $config) returns Bool:D {
    my Bool $result = True;
    CATCH {
        default { 
                $*ERR.say: .message; 
                $*ERR.say: "some kind of IO exception was caught!"; 
                my Str $content;
                given $file {
                    when 'hosts.h_ts' {
                        $content = q:to/END/;
                        #mappings #
                        ex         =>  fred@example.com :  22     # example entry

                        END
                    }
                }
                $content .=trim-trailing;
                if "$config/$file".IO !~~ :e || "$config/$file".IO.s == 0 {
                    "$config/$file".IO.spurt: $content, :append;
                }
                return True;
           }
    }
    my IO::CatHandle $fd = "$config/$file".IO.open: :w;
    given $file {
        when 'hosts.h_ts' {
            my Str $content = q:to/END/;
            #mappings #
            ex         =>  fred@example.com :  22     # example entry

            END
            $content .=trim-trailing;
            my Bool $r = $fd.put: $content;
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
            if !$result {
                "$config/$file".IO.spurt: $content, :append;
            }
        }
    } # given $file #
    my Bool $r = $fd.close;
    "error closing file: $config/$file".say if ! $r;
    $result ?&= $r;
    return $result;
} # sub generate-configs(Str:D $file, Str:D $config) returns Bool:D #

my Bool:D $please-edit = False;

sub check-files(Str:D @cfg-files, Str:D $config --> Bool:D) {
    my Bool $result = True;
    for @cfg-files -> $file {
        if "$config/$file".IO !~~ :e || "$config/$file".IO.s == 0 {
            $please-edit = True;
            if "/etc/skel/.local/share/syscon/$file".IO ~~ :f {
                try {
                    CATCH {
                        when X::IO::Copy { 
                            "could not copy /etc/skel/.local/share/syscon/$file -> $config/$file".say;
                            my Bool $r = generate-configs($file, $config); 
                            $result ?&= $r;
                        }
                    }
                    my Bool $r = "/etc/skel/.local/share/syscon/$file".IO.copy("$config/$file".IO);
                    if $r {
                        "copied /etc/skel/.local/share/syscon/$file -> $config/$file".say;
                    } else {
                        "could not copy /etc/skel/.local/share/syscon/$file -> $config/$file".say;
                    }
                    $result ?&= $r;
                }
            } else {
                my Bool $r = generate-configs($file, $config);
                "generated $config/$file".say if $r;
                $result ?&= $r;
            }
        }
    } # for @cfg-files -> $file # 
    return $result;
}

unless init-gui-editors(@host-config-files, $config, &generate-configs, &check-files) {
    exit 1;
}

#`«««
    ##################################################################
    #                                                                #
    #    grammars for parsing hosts.h_ts the hosts data base file    #
    #                                                                #
    ##################################################################
#»»»

grammar Key {
    regex key { \w+ [ [ '.' || '-' || '+' ]+ \w* ]* }
}

role KeyActions {
    method key($/) {
        my $k = (~$/).trim;
        make $k;
    }
}

grammar HostPort {
    token host-port         { \h+ <host-spec> \h+ ':' \s+ <port> \h* }
    token host-spec         { [ <user> '@' <host> || <host> ] }
    token user              { \w+ [ [ '-' || '.' ] \w+ ]* }
    token host              { \w+ [ [ '-' || '.' ] \w+ ]* }
    token port              { \d+ }
}

role HostPortActions {
    method host-port($/) { 
        my %hp = host => $/<host-spec>.made, port => $/<port>.made;
        make %hp;
    }
    method host-spec($/) {
        my Str $abs-host-spec;
        if $/<user> {
            $abs-host-spec = $/<user>.made ~ '@' ~ $/<host>.made;
        } else {
            $abs-host-spec = $/<host>.made;
        }
        make $abs-host-spec;
    }
    method user($/) {
        my $u = ~$/.trim;
        make $u;
    }
    method host($/) {
        my $h = ~$/.trim;
        make $h;
    }
    method port($/) {
        my Int:D $p = (~$/).trim.Int;
        make $p;
    }
}

grammar HostsFile is Key is HostPort {
    token TOP                 {  [ <line> [ \v+ <line> ]* \v* ]? }
    regex line                { [ <white-space-line> || <host-line> || <alias> || <header-line> || <line-of-hashes> || <comment-line> ] }
    regex white-space-line    { ^^ \h* $$ }
    token header-line         { ^^ \h* '#' <header> \h* $$ }
    token header              { 'key' \h+ 'sep' \h+ 'host-spec' \h+ ':' \h+ '#' \h+ 'comment' }
    token line-of-hashes      { ^^ \h* '#'+ $$ }
    regex comment-line        { ^^ \h* '#' <-[\v]>* $$ }
    token host-line           { ^^ <key> \h+ '=>' <host-port> [ '#' \h* <comment> \h* ]? $$ }
    token alias               { ^^ <key> \h+ '-->' \h+ <target=.key> \h+ [ '#' \h* <comment> \h* ]? $$ }
    token comment             { <-[\n]>* }
}

my $line-no = 0;
class HostFileActions does KeyActions does HostPortActions {
    #regex line                { [ <white-space-line> || <host-line> || <alias> || <header-line> || <line-of-hashes> || <comment-line> ] }
    method line($/) {
        my %line;
        if $/<white-space-line> {
            %line = $/<white-space-line>.made;
        }elsif $/<host-line> {
            %line = $/<host-line>.made;
        } elsif $/<alias> {
            %line = $/<alias>.made;
        } elsif $/<header-line> {
            %line = $/<header-line>.made;
        } elsif $/<line-of-hashes> {
            %line = $/<line-of-hashes>.made;
        } elsif $/<comment-line> {
            %line = $/<comment-line>.made;
        }
        make %line;
    }
    method white-space-line($/) {
        $line-no++;
        my %white-space-line = type => 'white-space-line', line-no => $line-no, value => ~$/;
        make ~$line-no => %white-space-line;
    }
    method header-line($/) {
        $line-no++;
        my %header-line = type => 'header-line', line-no => $line-no, value => $/<header>.made;
        make ~$line-no => %header-line;
    }
    method header($/) {
        my $header = ~$/;
        make $header;
    }
    method line-of-hashes($/) {
        $line-no++;
        my %line-of-hashes = type => 'line-of-hashes', line-no => $line-no, value => ~$/;
        make '##' => %line-of-hashes;
    }
    method comment-line($/) {
        $line-no++;
        my %comment-line = type => 'comment-line', line-no => $line-no, value => ~$/;
        make ~$line-no => %comment-line;
    }
    method comment($/)   { make ~$/; }
    method host-line   ($/)  {
        my %host-line = $/<host-port>.made;
        %host-line«type» = 'host';
        if $/<comment> {
            my Str $com = ~($/<comment>).trim;
            %host-line«comment» = $com;
        }
        $line-no++;
        %host-line«line-no» = $line-no;
        make $/<key>.made => %host-line;
    }
    method alias  ($/) {
        $line-no++;
        my %alias =  type => 'alias', line-no => $line-no, host => $/<target>.made;
        if $/<comment> {
            my $com = ~($/<comment>).trim;
            #$com ~~ s:g/ $<closer> = [ '}' ] /\\$<closer>/;
            %alias«comment» = $com;
        }
        make $/<key>.made => %alias;
    }
    method target ($/) { make $/<key>.made }
    method TOP($match) {
        my %top = $match<line>.map: *.made;
        $match.make: %top;
    }
} # class HostFileActions does KeyActions does HostPortActions #

grammar Line is Key is HostPort {
    regex TOP            {  [ <empty-str> || <commented-line> || <host-line> || <alias> ] }
    token empty-str      { ^ $ }
    token commented-line { \h* '#' .* }
    regex host-line      { <key> \h+ '=>' <host-port> [ '#' \h* <comment> \h* ]? }
    regex alias          { <key> \h+ '-->' \h+ <target=.key> \h+ [ '#' \h* <comment> \h* ]? }
    regex comment        { <-[\n]>* }
}

class LineActions does KeyActions does HostPortActions {
    method comment($/)   { make $/<comment>.made }
    method empty-str($/) {
        my %e;
        my $cont = ~$/;
        make %e;
    }
    method commented-line($/) {
        my %cl;
        my $cont = ~$/;
        make %cl;
    }
    method host-line   ($/)  {
        my %hl = $/<host-port>.made;
        %hl«type» = 'host';
        if $/<comment> {
            my Str $com = ~($/<comment>).trim;
            %hl«comment» = $com;
        }
        my %res = key => $/<key>.made, value => %hl;
        make %res;
    }
    method alias  ($/) {
        my %alias =  type => 'alias', host => $/<target>.made;
        if $/<comment> {
            my $com = ~($/<comment>).trim;
            #$com ~~ s:g/ $<closer> = [ '}' ] /\\$<closer>/;
            %alias«comment» = $com;
        }
        my %res = key => $/<key>.made, value => %alias;
        make %res;
    }
    method target ($/) { make $/<key>.made }
    method TOP($match) {
        my %top;
        if $match<host-line> {
            %top = $match<host-line>.made;
        } elsif $match<alias> {
            %top = $match<alias>.made;
        }
        $match.make: %top;
    }
} # class LineActions does KeyActions does HostPortActions #

grammar LineSyntax is Key is HostPort {
    regex TOP            {  [ <empty-str> || <commented-line> || <host-line> || <alias> ] }
    token empty-str      { ^ \h* $ }
    token commented-line { \h* '#' .* }
    regex host-line      { <key> \h+ '=>' <host-port> [ '#' \h* <comment> \h* ]? }
    regex alias          { <key> \h+ '-->' \h+ <target=.key> \h+ [ '#' \h* <comment> \h* ]? }
    regex comment        { <-[\n]>* }
}

class LineSyntaxActions does KeyActions does HostPortActions {
    method comment($/)   { make $/<comment>.made }
    method empty-str($/) {
        my %e;
        my $cont = ~$/;
        %e = key => '', value => $cont;
        make %e;
    }
    method commented-line($/) {
        my %cl;
        my $cont = ~$/;
        %cl = key => '#', value => $cont;
        make %cl;
    }
    method host-line   ($/)  {
        my %hl = $/<host-port>.made;
        %hl«type» = 'host';
        if $/<comment> {
            my Str $com = ~($/<comment>).trim;
            %hl«comment» = $com;
        }
        my %res = key => $/<key>.made, value => %hl;
        make %res;
    }
    method alias  ($/) {
        my %alias =  type => 'alias', host => $/<target>.made;
        if $/<comment> {
            my $com = ~($/<comment>).trim;
            #$com ~~ s:g/ $<closer> = [ '}' ] /\\$<closer>/;
            %alias«comment» = $com;
        }
        my %res = key => $/<key>.made, value => %alias;
        make %res;
    }
    method target ($/) { make $/<key>.made }
    method TOP($match) {
        my %top;
        if $match<host-line> {
            %top = $match<host-line>.made;
        } elsif $match<alias> {
            %top = $match<alias>.made;
        } elsif $match<commented-line> {
            %top = $match<commented-line>.made;
        } elsif $match<empty-str> {
            %top = $match<empty-str>.made;
        }
        $match.make: %top;
    }
} # class LineSyntaxActions does KeyActions does HostPortActions #

grammar CommentedLineStuff is Key is HostPort {
    regex empty-str           { ^^ \h* $$ }
    regex comment-line        { ^^ \h* '#' <-[\v]>*  $$ }
    token row-of-hashes       { ^^ '#' ** {2 .. ∞} $$ }
    token commeted-host-alias { ^^ \h* '#' [ <host-line> || <alias> ] }
    regex header-line         { ^^ \h* '#' <header-line-inner> }
    regex header-line-inner   { 'key' \h+ 'sep' \h+ 'host' [ '-spec' ]? \h+ ':' \h+ 'port' \h+ '#' \h+ 'comment' \h* }
    regex host-line           { <key> \h+ '=>' <host-port> [ '#' \h* <comment> \h* ]? }
    regex alias               { <key> \h+ '-->' \h+ <target=.key> \h+ [ '#' \h* <comment> \h* ]? }
    regex comment             { <-[\n]>* }
}

role CommentedLineStuffActions does KeyActions does HostPortActions {
    method comment($/)   { make $/<comment>.made }
    method empty-str($/) {
        my %e;
        my %value = type => 'empty-str', val => ~$/;
        %e = key => '', value => %value;
        make %e;
    }
    method comment-line($/) {
        my %cl;
        my %value = type => 'comment-line', val => ~$/;
        %cl = key => '#', value => %value;
        make %cl;
    }
    method host-line   ($/)  {
        my %hl = $/<host-port>.made;
        %hl«type» = 'host';
        if $/<comment> {
            my Str $com = ~($/<comment>).trim;
            %hl«comment» = $com;
        }
        my %res = key => $/<key>.made, value => %hl;
        make %res;
    }
    method alias  ($/) {
        my %alias =  type => 'alias', host => $/<target>.made;
        if $/<comment> {
            my $com = ~($/<comment>).trim;
            %alias«comment» = $com;
        }
        my %result = key => $/<key>.made, value => %alias;
        make %result;
    }
    method commeted-host-alias($/) {
        my %commeted-host-alias;
        if $/<host-line> {
            %commeted-host-alias = $/<host-line>.made;
            %commeted-host-alias«value»«type» = 'commeted-host';
        } elsif $/<alias> {
            %commeted-host-alias = $/<alias>.made;
            %commeted-host-alias«value»«type» = 'commeted-alias';
        }
        make %commeted-host-alias;
    }
    method row-of-hashes($/) {
        my %value = type => 'row-of-hashes', val => ~$/;
        my %row-of-hashes = key => '##', value => %value;
        make %row-of-hashes;
    }
    method header-line($/) {
        my %header-line = $/<header-line-inner>.made;
        make %header-line;
    }
    method header-line-inner($/) {
        my %value = type => 'header-line', val => '#' ~ ~$/;
        my %header-line-inner = key => '#header', value => %value;
        make %header-line-inner;
    }
    method target ($/) { make $/<key>.made }
} # role CommentedLineStuffActions does KeyActions does HostPortActions #

grammar CommentedLine is CommentedLineStuff {
    regex TOP                 { [ <empty-str> || <commeted-host-alias> || <row-of-hashes> || <header-line> || <host-line> || <alias> || <comment-line> ] }
}

class CommentedLineActions does CommentedLineStuffActions {
    method TOP($match) {
        my %top;
        if $match<host-line> {
            %top = $match<host-line>.made;
        } elsif $match<alias> {
            %top = $match<alias>.made;
        } elsif $match<commeted-host-alias> {
            %top = $match<commeted-host-alias>.made;
        } elsif $match<row-of-hashes> {
            %top = $match<row-of-hashes>.made;
        } elsif $match<header-line> {
            %top = $match<header-line>.made;
        } elsif $match<comment-line> {
            %top = $match<comment-line>.made;
        } elsif $match<empty-str> {
            %top = $match<empty-str>.made;
        }
        $match.make: %top;
    }
} # class CommentedLineActions does CommentedLineStuffActions #

grammar Stats is CommentedLineStuff {
    token TOP     { [ <line> [ \v <line> ]* \v? ] }
    regex line    { [ <empty-str> || <commeted-host-alias> || <row-of-hashes> || <header-line> || <host-line> || <alias> || <comment-line> ] }
}

class StatsActions does CommentedLineStuffActions {
    method line($/) {
        my %line;
        if $/<host-line> {
            %line = $/<host-line>.made;
        } elsif $/<alias> {
            %line = $/<alias>.made;
        } elsif $/<commeted-host-alias> {
            %line = $/<commeted-host-alias>.made;
        } elsif $/<row-of-hashes> {
            %line = $/<row-of-hashes>.made;
        } elsif $/<header-line> {
            %line = $/<header-line>.made;
        } elsif $/<comment-line> {
            %line = $/<comment-line>.made;
        } elsif $/<empty-str> {
            %line = $/<empty-str>.made;
        } else {
        }
        make %line;
    }
    method TOP($made) {
        my @lines = $made<line>».made;
        my %top = lines-total => @lines.elems,
        lines => @lines.values.grep( -> %val { %val«value»«type» eq 'host' || %val«value»«type» eq 'alias' } ).elems,
        commented => @lines.values.grep( -> %val { %val«value»«type» eq 'commeted-host' || %val«value»«type» eq 'commeted-alias' } ).elems,
        commented-hosts => @lines.values.grep( -> %val { %val«value»«type» eq 'commeted-host' } ).elems,
        commented-aliases => @lines.values.grep( -> %val { %val«value»«type» eq 'commeted-alias' } ).elems,
        rows-of-hashes => @lines.values.grep( -> %val { %val«value»«type» eq 'row-of-hashes' } ).elems,
        header-lines => @lines.values.grep( -> %val { %val«value»«type» eq 'header-line' } ).elems,
        comment-lines => @lines.values.grep( -> %val { %val«value»«type» eq 'comment-line' } ).elems,
        empty-strs => @lines.values.grep( -> %val { %val«value»«type» eq 'empty-str' } ).elems,
        hosts => @lines.values.grep( -> %val { %val«value»«type» eq 'host' } ).elems,
        aliases => @lines.values.grep( -> %val { %val«value»«type» eq 'alias' } ).elems;
        $made.make:  %top;
    }
} # class StatsActions does CommentedLineStuffActions #

grammar KeyValid is Key {
    token TOP { <key> }
}

class KeyValidAction does KeyActions {
    method TOP($/) { make $/<TOP>.made }
}

grammar Host is HostPort {
    token TOP { <host-spec> }
}

class HostValidActions does HostPortActions {
    method TOP($/) { make $/<TOP>.made }
}


my Str  @LINES     = slurp("$config/hosts.h_ts").split("\n");
my Str  @lines     = @LINES.grep({ !rx/^ \h* '#' .* $/ }).grep({ !rx/^ \h* $/ });
#dd @lines;
#my Str  %the-hosts = @lines.map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep({ !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / }).map: { my ($key, $value) = $_.split(rx/ \s*  '=>' \s* /, 2); my $e = $key => $value; $e };
#my Hash %the-lot   = @lines.grep({ !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / }).map: { my $e = $_; ($e ~~ rx/^ \s* $<key> = [ \w+ [ [ '.' || '-' || '@' || '+' ]+ \w* ]* ] \s* '=>' \s* $<host> = [ <-[ # ]>+ ] \s* [ '#' \s* $<comment> = [ .* ] ]?  $/) ?? (~$<key> => { value => (~$<host>).trim, comment => ($<comment> ?? ~$<comment> !! Str), }) !! { my ($key, $value) = $_.split(rx/ \s*  '=>' \s* /, 2); my $r = $key => $value; $r } };
my $actions = HostFileActions;
#my $test = HostsFile.parse(@lines.join("\x0A"), :enc('UTF-8'), :$actions).made;
#dd $test, $?NL;
my %whole-file = |(HostsFile.parse(@LINES.join("\x0A"), :enc('UTF-8'), :$actions).made);
#my %the-lot = |(HostsFile.parse(@lines.join("\x0A"), :enc('UTF-8'), :$actions).made);
#`«««
my %t = |%whole-file.kv.grep( -> $k, %v { %v«type» eq 'host' || %v«type» eq 'alias' }).map: -> @val {
                                                                                                        my $ky = @val[0];
                                                                                                        my %vl = |@val[1];
                                                                                                        $ky => %vl
                                                                                                    };
dd %t;
#»»»
my %the-lot = |%whole-file.kv.grep( -> $k, %v { %v«type» eq 'host' || %v«type» eq 'alias' }).map: -> @val {
                                                                                                              my $ky = @val[0];
                                                                                                              my %vl = |@val[1];
                                                                                                              $ky => %vl
                                                                                                          };

####################
#                  #
#  get the stats   #
#                  #
####################
my $statsactions = StatsActions;
my %stats;
{
    CATCH {
        default {
             $*ERR.say: .message;
             for .backtrace.full.reverse {
                 $*ERR.say: "{.file} line {.line}";
             }
            .rethrow;
        }
    }
    %stats   = Stats.parse(@LINES.join("\x0A"), :enc('UTF-8'), :actions($statsactions)).made;
}

#my Hash %the-lot = $test.List;
#my Hash %the-lot   = HostsFile.parse(@lines.join("\n"), actions  => HostFileActions.new).made;

#`«««
    ##################################
    #********************************#
    #*                              *#
    #*      Utility functions       *#
    #*                              *#
    #********************************#
    ##################################
#»»»


sub valid-key(Str:D $key --> Bool) is export {
    my $actions = KeyActions;
    my Str $match = KeyValid.parse($key, :rule('key'), :enc('UTF-8'), :$actions).made;
    without $match {
        return False;
    }
    return $key eq $match;
}


sub make-array( --> Array) is export {
    my @results;
    for %the-lot.kv -> $key, %val {
        my Str $comment = Str;
        $comment = %val«comment» with %val«comment»;
        my %row = key => $key;
        with $comment {
            %row«comment» = $comment;
        }
        #dd %row;
        @results.push(%row);
    }
    #dd @results;
    #@results = @results.map( -> %elt { %elt }).Array;
    #dd @results;
    return @results;
}

sub say-list-keys(Str $prefix, Bool:D $colour, Bool:D $syntax, Regex:D $pattern, Int:D $page-length --> Bool:D) is export {
    my @rows = make-array();
    my Str:D @fields = |qw[key comment];
    #dd @fields, @rows;
    my %defaults;
    sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) {
        for @fields -> $field {
            my Str:D $value = ~(%row{$field} // '');
            #dd $field, $value;
            return True if $value.starts-with($prefix, :ignorecase) && $value ~~ $pattern;
        }
        return False;
    } # sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) #
    sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        #dd $indx, $field, $colour, $syntax, @fields;
        if $colour {
            if $syntax { 
                return t.color(0, 255, 255) ~ $field;
            } else {
                return t.color(0, 255, 255) ~ $field;
            }
        } else {
            return $field;
        }
    } # sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) #
    sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        if $colour {
            if $syntax {
                given $field {
                    when 'key'     { return t.color(0, 255, 255)   ~ ' # ';   }
                    when 'comment' { return t.color(0, 0, 255)     ~ '  ';    }
                    default { return ''; }
                }
            } else {
                given $field {
                    when 'key'     { return t.color(0, 255, 255)   ~ ' # ';   }
                    when 'comment' { return t.color(0, 255, 255)   ~ '  ';    }
                    default { return ''; }
                }
            }
        } else {
            given $field {
                when 'key'     { return ' # ';   }
                when 'comment' { return '  ';    }
                default        { return '';      }
            }
        }
    } # sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) #
    sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        my Str:D $val = ~($value // ''); #`««« assumming $value is a Str:D »»»
        #dd $val, $value, $field;
        if $syntax {
            given $field {
                when 'key'     { return t.color(0, 255, 255) ~ $val; }
                when 'comment' { return t.color(0, 0, 255) ~ $val;   }
                default        { return t.color(255, 0, 0) ~ '';     }
            } # given $field #
        } elsif $colour {
            given $field {
                when 'key'     { return t.color(0, 0, 255) ~ $val; }
                when 'comment' { return t.color(0, 0, 255) ~ $val; }
                default        { return t.color(255, 0, 0) ~ '';   }
            }
        } else {
            given $field {
                when 'key'     { return $val;                      }
                when 'comment' { return ~$val;                     }
                default        { return '';                        }
            }
        }
    } # sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) #
    sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        if $syntax {
                given $field {
                    when 'key'     { return t.color(0, 0, 255) ~ ' # '; }
                    when 'comment' { return t.color(0, 0, 255) ~ '  ';  }
                    default        { return t.color(255, 0, 0) ~ '';    }
                }
        } elsif $colour {
                given $field {
                    when 'key'     { return t.color(0, 0, 255) ~ ' # '; }
                    when 'comment' { return t.color(0, 0, 255) ~ '  ';  }
                    default        { return t.color(255, 0, 0) ~ '';    }
                }
        } else {
                given $field {
                    when 'key'     { return ' # '; }
                    when 'comment' { return '  ';  }
                    default        { return '';    }
                }
        }
    } # sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) #
    sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) {
        if $colour {
            if $syntax { 
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3; # three heading lines. #
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            } else {
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3;
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            }
        } else {
            return '';
        }
    } # sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) #
    return list-by($prefix, $colour, $syntax, $page-length,
                  $pattern, @fields, %defaults, @rows,
                  :&include-row, 
                  :&head-value, 
                  :&head-between,
                  :&field-value, 
                  :&between,
                  :&row-formatting);
} # sub say-list-keys(Str $prefix, Bool:D $colour is copy, Bool:D $syntax, Regex:D $pattern, Int:D $page-length --> Bool:D) is export #

sub list-by-all(Str:D $prefix, Bool:D $colour, Bool:D $syntax, Int:D $page-length, Regex:D $pattern --> Bool:D) is export {
    my Str:D $key-name = 'key';
    my Str:D @fields = 'host', 'port', 'comment';
    my   %defaults = port => 22;
    sub include-row(Str:D $prefix, Regex:D $pattern, Str:D $key, Str:D @fields, %row --> Bool:D) {
        return True if $key.starts-with($prefix, :ignorecase) && $key ~~ $pattern;
        for @fields -> $field {
            my Str:D $value = '';
            with %row{$field} { #`««« if %row{$field} does not exist then a Any will be retured,
                                  and if some cases, you may return undefined values so use
                                  some sort of guard this is one way to do that, you could
                                  use %row{$field}:exists or :!exists or // perhaps.
                                  TIMTOWTDI rules as always. »»»
                $value = ~%row{$field};
            }
            return True if $value.starts-with($prefix, :ignorecase) && $value ~~ $pattern;
        }
        return False;
    } # sub include-row(Str:D $prefix, Regex:D $pattern, Str:D $key, @fields, %row --> Bool:D) #
    sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        if $syntax {
            t.color(0, 255, 255) ~ $field;
        } elsif $colour {
            t.color(0, 255, 255) ~ $field;
        } else {
            return $field;
        }
    } #`««« sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) »»»
    sub head-between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        if $colour {
            if $syntax {
                given $field {
                    when 'key'     { return t.color(0, 255, 255) ~ ' sep '; }
                    when 'host'    { return t.color(0, 255, 255) ~ ' : ';   }
                    when 'port'    { return t.color(0, 255, 255)   ~ ' # ';   }
                    when 'comment' { return t.color(0, 0, 255)   ~ '  ';    }
                    default { return ''; }
                }
            } else {
                given $field {
                    when 'key'     { return t.color(0, 255, 255)   ~ ' sep '; }
                    when 'host'    { return t.color(0, 255, 255)   ~ ' : ';   }
                    when 'port'    { return t.color(0, 255, 255)   ~ ' # ';   }
                    when 'comment' { return t.color(0, 255, 255)   ~ '  ';    }
                    default { return ''; }
                }
            }
        } else {
            given $field {
                when 'key'     { return ' sep '; }
                when 'host'    { return ' : ';   }
                when 'port'    { return ' # ';   }
                when 'comment' { return '  ';    }
                default        { return '';      }
            }
        }
    } #`««« sub head-between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) »»»
    sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        if $syntax {
            given $field {
                when 'key'     { return t.color(0, 255, 255) ~ ~$value; }
                when 'host'    {
                    my Str:D $type = %row«type»;
                    if $type eq 'host' {
                        return t.color(255, 0, 255) ~ ~$value;
                    } else {
                        return t.color(0, 255, 255) ~ ~$value;
                    }
                }
                when 'port'    { 
                    my Str:D $type = %row«type»;
                    if $type eq 'host' {
                        return t.color(255, 0, 255) ~ ~$value;
                    } else {
                        return t.color(255, 0, 255) ~ '';
                    }
                }
                when 'comment' { return t.color(0, 0, 255) ~ ~$value; }
                default        { return t.color(255, 0, 0) ~ '';      }
            } # given $field #
        } elsif $colour {
            given $field {
                when 'key'     { return t.color(0, 0, 255) ~ ~$value; }
                when 'host'    { return t.color(0, 0, 255) ~ ~$value; }
                when 'port'    { 
                    my Str:D $type = %row«type»;
                    if $type eq 'host' {
                        return t.color(0, 0, 255) ~ ~$value;
                    } else {
                        return t.color(0, 0, 255) ~ '';
                    }
                }
                when 'comment' { return t.color(0, 0, 255) ~ ~$value; }
                default        { return t.color(255, 0, 0) ~ '';      }
            }
        } else {
            given $field {
                when 'key'     { return ~$value; }
                when 'host'    { return ~$value; }
                when 'port'    { 
                    my Str:D $type = %row«type»;
                    if $type eq 'host' {
                        return ~$value;
                    } else {
                        return '';
                    }
                }
                when 'comment' { return ~$value; }
                default        { return '';      }
            }
        }
    } #`««« sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) »»»
    sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        if $syntax {
                given $field {
                    when 'key'     {
                        my Str:D $type = %row«type»;
                        if $type eq 'host' {
                            return t.color(255, 0, 0) ~ '  => ';
                        } else {
                            return t.color(255, 0, 0) ~ ' --> ';
                        }
                    }
                    when 'host'    {
                        my Str:D $type = %row«type»;
                        if $type eq 'host' {
                            return t.color(255, 0, 0) ~ ' : ';
                        } else {
                            return t.color(255, 0, 0) ~ '   ';
                        }
                    }
                    when 'port'    { return t.color(0, 0, 255) ~ ' # '; }
                    when 'comment' { return t.color(0, 0, 255) ~ '  ';  }
                    default        { return t.color(255, 0, 0) ~ '';    }
                }
        } elsif $colour {
                given $field {
                    when 'key'     {
                        my Str:D $type = %row«type»;
                        if $type eq 'host' {
                            return t.color(0, 0, 255) ~ '  => ';
                        } else {
                            return t.color(0, 0, 255) ~ ' --> ';
                        }
                    }
                    when 'host'    {
                        my Str:D $type = %row«type»;
                        if $type eq 'host' {
                            return t.color(0, 0, 255) ~ ' : ';
                        } else {
                            return t.color(0, 0, 255) ~ '   ';
                        }
                    }
                    when 'port'    { return t.color(0, 0, 255) ~ ' # '; }
                    when 'comment' { return t.color(0, 0, 255) ~ '  ';  }
                    default        { return t.color(255, 0, 0) ~ '';    }
                }
        } else {
                given $field {
                    when 'key'     {
                        my Str:D $type = %row«type»;
                        if $type eq 'host' {
                            return '  => ';
                        } else {
                            return ' --> ';
                        }
                    }
                    when 'host'    {
                        my Str:D $type = %row«type»;
                        if $type eq 'host' {
                            return ' : ';
                        } else {
                            return '   ';
                        }
                    }
                    when 'port'    { return ' # '; }
                    when 'comment' { return '  ';  }
                    default        { return '';    }
                }
        }
    } #`««« sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) »»»
    sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) {
        if $colour {
            if $syntax { 
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3; # three heading lines. #
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            } else {
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3;
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            }
        } else {
            return '';
        }
    } #`««« sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) »»»
    return list-by($prefix, $colour, $syntax, $page-length, $pattern, $key-name, @fields, %defaults, %the-lot,
                                            :&include-row, :&head-value, :&head-between, :&field-value, :&between, :&row-formatting);
} #`««« sub list-by-all(Str:D $prefix, Bool:D $colour is copy, Bool:D $syntax, Int:D $page-length, Regex:D $pattern --> Bool:D) is export »»»

sub list-commented(Str:D $prefix, Bool:D $colour, Bool:D $syntax, Int:D $page-length, Regex:D $pattern --> Bool) is export {
    my @data;
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my $actions = CommentedLineActions;
    my $ln = $input.get;
    while !$input.eof {
        my %row;
        #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
        #dd $test;
        my %val = CommentedLine.parse($ln, :enc('UTF-8'), :$actions).made;
        my Str $key         = %val«key»;
        my %v               = %val«value»;
        my Str:D $type      = %v«type»;
        %row                = key => $key, type => $type;
        if $type eq 'commeted-alias' || $type eq 'commeted-host' {
            my Str $host;
            with %v«host» {
                $host        = %v«host»;
                %row«host»   =  $host;
            }
            my Int $port = 0;
            if $type eq 'commeted-host' {
                $port           = %v«port».Int;
                %row«port»      = $port;
            }
            with %v«comment» {
                my Str $comment = %v«comment»;
                %row«comment»   = $comment;
            }
            @data.push: %row;
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        my %row;
        #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
        #dd $test;
        my %val = CommentedLine.parse($ln, :enc('UTF-8'), :$actions).made;
        my Str $key         = %val«key»;
        my %v               = %val«value»;
        my Str:D $type      = %v«type»;
        %row                = key => $key, type => $type;
        if $type eq 'commeted-alias' || $type eq 'commeted-host' {
            my Str $host;
            with %v«host» {
                $host      = %v«host»;
                %row«host»   =  $host;
            }
            my Int $port = 0;
            if $type eq 'commeted-host' {
                $port           = %v«port».Int;
                %row«port»      = $port;
            }
            with %v«comment» {
                my Str $comment = %v«comment»;
                %row«comment»   = $comment;
            }
            @data.push: %row;
        }
    } # $ln #
    $input.close();
    my Str:D @fields = 'key', 'host', 'port', 'comment';
    my   %defaults = port => 22;
    sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) {
        for @fields -> $field {
            my Str:D $value = '';
            with %row{$field} { #`««« if %row{$field} does not exist then a Any will be retured,
                                  and if some cases, you may return undefined values so use
                                  some sort of guard this is one way to do that, you could
                                  use %row{$field}:exists or :!exists or // perhaps.
                                  TIMTOWTDI rules as always. »»»
                $value = ~%row{$field};
            }
            return True if $value.starts-with($prefix, :ignorecase) && $value ~~ $pattern;
        }
        return False;
    } # sub include-row(Str:D $prefix, Regex:D $pattern, Str:D $key, @fields, %row --> Bool:D) #
    sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        if $syntax {
            t.color(0, 255, 255) ~ (($field eq 'key') ?? "#$field" !! $field);
        } elsif $colour {
            t.color(0, 255, 255) ~ (($field eq 'key') ?? "#$field" !! $field);
        } else {
            return (($field eq 'key') ?? "#$field" !! $field);
        }
    } #`««« sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) »»»
    sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        if $colour {
            if $syntax {
                given $field {
                    when 'key'     { return t.color(0, 255, 255) ~ ' sep '; }
                    when 'host'    { return t.color(0, 255, 255) ~ ' : ';   }
                    when 'port'    { return t.color(0, 255, 255)   ~ ' # ';   }
                    when 'comment' { return t.color(0, 0, 255)   ~ '  ';    }
                    default { return ''; }
                }
            } else {
                given $field {
                    when 'key'     { return t.color(0, 255, 255)   ~ ' sep '; }
                    when 'host'    { return t.color(0, 255, 255)   ~ ' : ';   }
                    when 'port'    { return t.color(0, 255, 255)   ~ ' # ';   }
                    when 'comment' { return t.color(0, 255, 255)   ~ '  ';    }
                    default { return ''; }
                }
            }
        } else {
            given $field {
                when 'key'     { return ' sep '; }
                when 'host'    { return ' : ';   }
                when 'port'    { return ' # ';   }
                when 'comment' { return '  ';    }
                default        { return '';      }
            }
        }
    } #`««« sub head-between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) »»»
    sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        if $syntax {
            given $field {
                when 'key'     { return t.color(0, 255, 255) ~ '#' ~ ~$value; }
                when 'host'    {
                    my Str:D $type = %row«type»;
                    if $type eq 'commeted-host' {
                        return t.color(255, 0, 255) ~ ~$value;
                    } else {
                        return t.color(0, 255, 255) ~ ~$value;
                    }
                }
                when 'port'    { 
                    my Str:D $type = %row«type»;
                    if $type eq 'commeted-host' {
                        return t.color(255, 0, 255) ~ ~$value;
                    } else {
                        return t.color(255, 0, 255) ~ '';
                    }
                }
                when 'comment' { return t.color(0, 0, 255) ~ ~$value; }
                default        { return t.color(255, 0, 0) ~ '';      }
            } # given $field #
        } elsif $colour {
            given $field {
                when 'key'     { return t.color(0, 0, 255) ~ '#' ~ ~$value; }
                when 'host'    { return t.color(0, 0, 255) ~       ~$value; }
                when 'port'    { 
                    my Str:D $type = %row«type»;
                    if $type eq 'commeted-host' {
                        return t.color(0, 0, 255) ~ ~$value;
                    } else {
                        return t.color(0, 0, 255) ~ '';
                    }
                }
                when 'comment' { return t.color(0, 0, 255) ~ ~$value; }
                default        { return t.color(255, 0, 0) ~ '';      }
            }
        } else {
            given $field {
                when 'key'     { return '#' ~ ~$value; }
                when 'host'    { return       ~$value; }
                when 'port'    { 
                    my Str:D $type = %row«type»;
                    if $type eq 'commeted-host' {
                        return ~$value;
                    } else {
                        return '';
                    }
                }
                when 'comment' { return ~$value; }
                default        { return '';      }
            }
        }
    } #`««« sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) »»»
    sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        if $syntax {
                given $field {
                    when 'key'     {
                        my Str:D $type = %row«type»;
                        if $type eq 'commeted-host' {
                            return t.color(255, 0, 0) ~ '  => ';
                        } else {
                            return t.color(255, 0, 0) ~ ' --> ';
                        }
                    }
                    when 'host'    {
                        my Str:D $type = %row«type»;
                        if $type eq 'commeted-host' {
                            return t.color(255, 0, 0) ~ ' : ';
                        } else {
                            return t.color(255, 0, 0) ~ '   ';
                        }
                    }
                    when 'port'    { return t.color(0, 0, 255) ~ ' # '; }
                    when 'comment' { return t.color(0, 0, 255) ~ '  ';  }
                    default        { return t.color(255, 0, 0) ~ '';    }
                }
        } elsif $colour {
                given $field {
                    when 'key'     {
                        my Str:D $type = %row«type»;
                        if $type eq 'commeted-host' {
                            return t.color(0, 0, 255) ~ '  => ';
                        } else {
                            return t.color(0, 0, 255) ~ ' --> ';
                        }
                    }
                    when 'host'    {
                        my Str:D $type = %row«type»;
                        if $type eq 'commeted-host' {
                            return t.color(0, 0, 255) ~ ' : ';
                        } else {
                            return t.color(0, 0, 255) ~ '   ';
                        }
                    }
                    when 'port'    { return t.color(0, 0, 255) ~ ' # '; }
                    when 'comment' { return t.color(0, 0, 255) ~ '  ';  }
                    default        { return t.color(255, 0, 0) ~ '';    }
                }
        } else {
                given $field {
                    when 'key'     {
                        my Str:D $type = %row«type»;
                        if $type eq 'commeted-host' {
                            return '  => ';
                        } else {
                            return ' --> ';
                        }
                    }
                    when 'host'    {
                        my Str:D $type = %row«type»;
                        if $type eq 'commeted-host' {
                            return ' : ';
                        } else {
                            return '   ';
                        }
                    }
                    when 'port'    { return ' # '; }
                    when 'comment' { return '  ';  }
                    default        { return '';    }
                }
        }
    } #`««« sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) »»»
    sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) {
        if $colour {
            if $syntax { 
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3; # three heading lines. #
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            } else {
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3;
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            }
        } else {
            return '';
        }
    } #`««« sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) »»»
    return list-by($prefix, $colour, $syntax, $page-length,
                  $pattern, @fields, %defaults, @data,
                  :&include-row, 
                  :&head-value, 
                  :&head-between,
                  :&field-value, 
                  :&between,
                  :&row-formatting);
} # sub list-commented(Str:D $prefix, Bool:D $colour, Bool:D $syntax, Int:D $page-length, Regex:D $pattern --> Bool) is export #

sub stats(Str:D $prefix, Bool:D $colour, Bool:D $syntax, Regex:D $pattern --> Bool:D) is export {
    my Str:D @quanties = 'lines-total', 'header-lines', 'rows-of-hashes',
                          'empty-strs', 'comment-lines', 'commented',
                          'commented-hosts', 'commented-aliases', 'lines', 'hosts', 'aliases';
    my @rows;
    for @quanties -> $quantity {
        my %row = quantity => $quantity, value => %stats{$quantity};
        @rows.push: %row;
    }
    my Str:D @fields     = 'quantity', 'value';
    my Str:D %fancynames = quantity => 'Quantity', value => 'Number';
    my Str:D %prompts    = lines-total => 'number of lines in file:',
                           header-lines => 'number of header lines in file:',
                           rows-of-hashes => 'rows of hashes in file:',
                           empty-strs => 'empty lines in file:',
                           comment-lines => 'comment lines:',
                           commented => 'trashed lines:',
                           commented-aliases => 'trashed aliases in db:',
                           commented-hosts => 'trashed hosts in db:',
                           lines => 'number of elts in db:',
                           hosts => 'number of hosts in db:',
                           aliases => 'number of aliases in db:';
    my %defaults;
    my $page-length = 30; # basically $page-length is redundant here. #
    sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) {
        my Str:D $value = ~(%prompts{%row«quantity»} // '');
        return True if $value.starts-with($prefix, :ignorecase) && $value ~~ $pattern;
        return False;
    } # sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) #
    sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        #dd $indx, $field, $colour, $syntax, @fields;
        if $colour {
            if $syntax { 
                return t.color(0, 255, 255) ~ %fancynames{$field};
            } else {
                return t.color(0, 255, 255) ~ %fancynames{$field};
            }
        } else {
            return %fancynames{$field};
        }
    } # sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) #
    sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        return ' ' x 5;
    } # sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) #
    sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        my Str:D $val = ~($value // ''); #`««« assumming $value is a Str:D »»»
        #dd $val, $value, $field;
        if $syntax {
            given $field {
                when 'quantity' { return t.color(255, 0, 0)   ~ %prompts{$val}; }
                when 'value'    { return t.color(255, 0, 255) ~ $val;           }
                default         { return t.color(255, 0, 0)   ~ $val;           }
            } # given $field #
        } elsif $colour {
            given $field {
                when 'quantity' { return t.color(0, 0, 255) ~ %prompts{$val}; }
                when 'value'    { return t.color(0, 0, 255) ~ $val;           }
                default         { return t.color(255, 0, 0) ~ $val;           }
            } # given $field #
        } else {
            given $field {
                when 'quantity' { return %prompts{$val}; }
                when 'value'    { return $val;           }
                default         { return $val;           }
            } # given $field #
        }
    } # sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) #
    sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        return ' ' x 5;
    } # sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) #
    sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) {
        if $colour {
            if $syntax { 
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3; # three heading lines. #
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            } else {
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3;
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            }
        } else {
            return '';
        }
    } # sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) #
    return list-by($prefix, $colour, $syntax, $page-length,
                  $pattern, @fields, %defaults, @rows,
                  :!sort,
                  :&include-row, 
                  :&head-value, 
                  :&head-between,
                  :&field-value, 
                  :&between,
                  :&row-formatting);
} # sub stats(Str:D $prefix, Bool:D $colour, Bool:D $syntax, Regex:D $pattern --> Bool:D) is export #

subset PortVal is export of Int where 0 < * <= 9_223_372_036_854_775_807;

sub add-host(Str:D $key, Str:D $host is copy, PortVal:D $port, Bool $force, Str $comment --> Bool) is export {
    unless valid-key($key) {
        $*ERR.say: "invalid key: $key";
        return False;
    }
    if %the-lot{$key}:exists {
        if $force {
            CATCH {
                when X::IO::Rename {
                    $*ERR.say: $_;
                    return False;
                }
                default: {
                    $*ERR.say: $_;
                    return False;
                }
            }
            my Str $line = sprintf "%-20s  => %-40s : %-7d", $key, $host, $port;
            with $comment {
                $line ~= " # $comment";
            }
            my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
            my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
            my Str $ln;
            while $ln = $input.get {
                if $ln ~~ rx/^ \s* <$key> \h* [ '-->' || '=>' ] \h* .* $/ {
                    $output.say: $line;
                } else {
                    $output.say: $ln
                }
            }
            $input.close;
            $output.close;
            if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
                return True;
            } else {
                return False;
            }
        } else {
            $*ERR.say: "duplicate key use -s|--set|--force to override";
            return False;
        }
    }
    my Str $config-path = "$config/hosts.h_ts";
    my Str $line = sprintf "%-20s  => %-40s : %-7d", $key, $host, $port;
    with $comment {
        $line ~= " # $comment";
    }
    $line ~= "\n";
    $config-path.IO.spurt($line, :append);
    return True;
} # sub add-host(Str:D $key, Str:D $host, PortVal:D $port, Bool $force, Str $comment --> Bool) is export #

sub delete-key(Str:D $key, Bool:D $trash --> Bool) is export {
    CATCH {
        when X::IO::Rename {
            $*ERR.say: $_;
            return False;
        }
        default: {
            $*ERR.say: $_;
            return False;
        }
    }
    unless valid-key($key) {
        $*ERR.say: "invalid key: $key";
        return False;
    }
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
    my Str $ln;
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/^ $key \h* [ '-->' || '=>' ] \h* [ <-[ # : ]>+ ] \h* [ ':' \h* \d+ ]? \h* [ '#' \h* .* ]? $/ {
            if $trash {
                $output.say: "#$ln";
            }
        } else {
            $output.say: $ln
        }
        $ln = $input.get;
    }
    if $ln {
        if $ln ~~ rx/^ $key \h* [ '-->' || '=>' ] \h* [ <-[ # : ]>+ ] \h* [ ':' \h* \d+ ]? \h* [ '#' \h* .* ]? $/ {
            if $trash {
                $output.say: "#$ln";
            }
        } else {
            $output.say: $ln
        }
    }
    $input.close;
    $output.close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        return False;
    }
} # sub delete-key(Str:D $key, Bool:D $trash --> Bool) is export #

sub undelete(Str:D $key-to-find --> Bool) is export {
    #`«««
    CATCH {
        when X::IO::Rename {
            $*ERR.say: $_;
            return False;
        }
        default: {
            $*ERR.say: $_;
            return False;
        }
    }
    #»»»
    if %the-lot{$key-to-find}:exists {
        "key $key-to-find exists delete undelete would override it.".say;
        return False;
    }
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    my Str $ln;
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
        } elsif $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth(~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } elsif $ln ~~ rx/^ \h+ '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]? ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth('#' ~ ~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
        } elsif $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth(~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]? ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            $key-width         = max($key-width,     wcswidth('#' ~ ~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        }
    } # $ln #
    #$key-width     += 2;
    #$host-width    += 2;
    $port-width    += 2;
    #$comment-width += 2;
    $key-width = 20 if $key-width < 20;
    $host-width = 70 if $host-width < 70;
    $port-width = 9 if $port-width < 9;
    $input.seek(0, SeekFromBeginning);
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
            $output.say: $ln
        } elsif $ln ~~ rx/^ \h* $<key> = [ \w+ [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            my Str $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, (($port == 0) ?? '' !! ': ' ~ "$port");
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w+ [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \w+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Str:D $port = '';
            with $<port> {
                $port = ': ' ~ ~$<port>;
            }
            my Str $line;
            if $key-to-find.trim eq (~$<key>).trim {
                $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, $port;
            } else {
                $line = sprintf "#%-*s %-3s %-*s %-*s", $key-width - 1, ~$<key>, ~$<type>, $host-width, $host, $port-width, $port;
            }
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } else {
            $output.say: $ln
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
            $output.say: $ln
        } elsif $ln ~~ rx/^ \h* $<key> = [ \w+ [ <-[\h]>+ \w+ ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            my Str $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, (($port == 0) ?? '' !! ': ' ~ "$port");
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w+ [ <-[\h]>+ \w+ ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \w+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Str:D $port = '';
            with $<port> {
                $port = ': ' ~ ~$<port>;
            }
            my Str $line;
            if $key-to-find.trim eq (~$<key>).trim {
                $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, $port;
            } else {
                $line = sprintf "#%-*s %-3s %-*s %-*s", $key-width - 1, ~$<key>, ~$<type>, $host-width, $host, $port-width, $port;
            }
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } else {
            $output.say: $ln
        }
    } # $ln #
    $input.close;
    $output.close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        die "move failed";
    }
} # sub undelete(Str:D $key-to-find --> Bool) is export #

sub empty-trash( --> Bool) is export {
    #`«««
    CATCH {
        when X::IO::Rename {
            $*ERR.say: $_;
            return False;
        }
        default: {
            $*ERR.say: $_;
            return False;
        }
    }
    #»»»
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    my Str $ln;
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
        } elsif $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth(~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } elsif $ln ~~ rx/^ \h+ '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]? ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth('#' ~ ~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
        } elsif $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth(~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]? ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            $key-width         = max($key-width,     wcswidth('#' ~ ~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        }
    } # $ln #
    #$key-width     += 2;
    #$host-width    += 2;
    $port-width    += 2;
    #$comment-width += 2;
    $key-width = 20 if $key-width < 20;
    $host-width = 70 if $host-width < 70;
    $port-width = 9 if $port-width < 9;
    $input.seek(0, SeekFromBeginning);
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
            $output.say: $ln
        } elsif $ln ~~ rx/^ \h* $<key> = [ \w+ [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            my Str $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, (($port == 0) ?? '' !! ': ' ~ "$port");
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w+ [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \w+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            # do nothing we want to delete this #
        } else {
            $output.say: $ln
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
            $output.say: $ln
        } elsif $ln ~~ rx/^ \h* $<key> = [ \w+ [ <-[\h]>+ \w+ ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            my Str $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, (($port == 0) ?? '' !! ': ' ~ "$port");
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w+ [ <-[\h]>+ \w+ ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \w+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            # do nothing we want to delete this #
        } else {
            $output.say: $ln
        }
    } # $ln #
    $input.close;
    $output.close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        die "move failed";
    }
} # sub empty-trash( --> Bool) is export #

sub add-comment(Str:D $key, Str:D $comment --> Bool) is export {
    CATCH {
        when X::IO::Rename {
            $*ERR.say: $_;
            return False;
        }
        default: {
            $*ERR.say: $_;
            return False;
        }
    }
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
    my Str $ln;
    my $actions = LineActions;
    $ln = $input.get;
    while !$input.eof {
        #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
        #dd $test;
        my %val = Line.parse($ln, :enc('UTF-8'), :$actions).made;
        if %val {
            my Str $k = %val«key»;
            my %v = %val«value»;
            my Str:D $type = %v«type»;
            my Str:D $host = %v«host»;
            $host         .=trim;
            my Int $port = 0;
            my Str:D $type-spec = '-->';
            if $type eq 'host' {
                $port = %v«port».Int;
                $type-spec = ' =>';
            }
            my Str $line = sprintf "%-20s %s %-40s %-9s", ~$k, $type-spec, $host, (($port == 0) ?? '' !! ": $port");
            if $key eq $k {
                $line ~= " # $comment" unless $comment.trim eq '';
            } orwith %v«comment» {
                $line ~= " # %v«comment»" unless %v«comment».trim eq '';
            }
            $output.say: $line;
        } else {
            $output.say: $ln
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        my %val = Line.parse($ln, :enc('UTF-8'), :$actions).made;
        if %val {
            my Str $k = %val«key»;
            my %v = %val«value»;
            my Str:D $type = %v«type»;
            my Str:D $host = %v«host»;
            $host         .=trim;
            my Int $port = 0;
            my Str:D $type-spec = '-->';
            if $type eq 'host' {
                $port = %v«port».Int;
                $type-spec = ' =>';
            }
            my Str $line = sprintf "%-20s %s %-40s %-9s", ~$k, $type-spec, $host, (($port == 0) ?? '' !! ": $port");
            if $key eq $k {
                $line ~= " # $comment" unless $comment.trim eq '';
            } orwith %v«comment» {
                $line ~= " # %v«comment»" unless %v«comment».trim eq '';
            }
            $output.say: $line;
        } else {
            $output.say: $ln
        }
    } # if $ln #
    $input.close;
    $output.close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        return False;
    }
} # sub add-comment(Str:D $key, Str:D $comment --> Bool) is export #

sub add-alias(Str:D $key, Str:D $target, Bool:D $force is copy,
                Bool:D $overwrite-hosts,
                Str $comment is copy --> Bool) is export {
    unless valid-key($key) {
        $*ERR.say: "invalid key: $key";
        return False;
    }
    if $key eq $target {
        $*ERR.say: "Error key equals target";
        return False;
    }
    if %the-lot{$target}:exists {
        my %val = %the-lot{$target};
        without $comment {
            with %val«comment» {
                $comment = %val«comment»;
            }
        }
        $force = True if $overwrite-hosts;
        if %the-lot{$key}:exists {
            if $force {
                CATCH {
                    when X::IO::Rename {
                        $*ERR.say: $_;
                        return False;
                    }
                    default: {
                        $*ERR.say: $_;
                        return False;
                    }
                }
                my %kval = %the-lot{$key};
                unless %kval«type» eq 'alias' || $overwrite-hosts {
                    "$key is not an alias it's a {%kval«type»} use -d|--really-force|--overwrite-hosts to override".say;
                    return False;
                }
                without $comment {
                    with %kval«comment» {
                        $comment = %kval«comment»;
                    }
                }
                my Str $line = sprintf "%-20s --> %-50s", $key, $target;
                with $comment {
                    $line ~= " # $comment";
                }
                my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
                my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
                my Str $ln = $input.get;
                while !$input.eof {
                    if $ln ~~ rx/^ \s* $key \s* $<type> = [ '-->' | '=>' ] \s* .* $/ {
                        if ~$<type> eq 'alias' || $overwrite-hosts {
                            $output.say: $line;
                        } else {
                            $output.say: $ln
                        }
                    } else {
                        $output.say: $ln
                    }
                    $ln = $input.get;
                } # while $input.eof  #
                if $ln { # left overs #
                    if $ln ~~ rx/^ \s* $key \s* $<type> = [ '-->' | '=>' ] \s* .* $/ {
                        if ~$<type> eq 'alias' || $overwrite-hosts {
                            $output.say: $line;
                        } else {
                            $output.say: $ln
                        }
                    } else {
                        $output.say: $ln
                    }
                } # if $ln #
                $input.close;
                $output.close;
                if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
                    return True;
                } else {
                    return False;
                }
            } else {
                $*ERR.say: "duplicate key use -s|--set|--force to override";
                return False;
            }
        } else {
            my Str $config-path = "$config/hosts.h_ts";
            my Str $line = sprintf "%-20s --> %-50s", $key, $target;
            with $comment {
                $line ~= " # $comment";
            }
            $line ~= "\n";
            $config-path.IO.spurt($line, :append);
            return True;
        }
    } else {
        "target: $target doesnot exist".say;
        return False;
    }
} # sub add-alias(Str:D $key, Str:D $target, Bool:D $force is copy, Bool:D $overwrite-hosts, Str $comment is copy --> Bool) is export #

#`«««
    ##########################################################
    #                                                        #
    # some vanity functions no real point in their existance #
    #                                                        #
    ##########################################################
#»»»

sub tidy-file( --> Bool) is export {
    #`«««
    CATCH {
        when X::IO::Rename {
            $*ERR.say: $_;
            return False;
        }
        default: {
            $*ERR.say: $_;
            return False;
        }
    }
    #»»»
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my IO::Handle:D $output = "$config/hosts.h_ts.new".IO.open: :w, :nl-out("\n"), :chomp(True);
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    my Str $ln;
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
        } elsif $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth(~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } elsif $ln ~~ rx/^ \h+ '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]? ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth('#' ~ ~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } else {
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
        } elsif $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth(~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        } elsif $ln ~~ rx/^ \h+ '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]? ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = (~$<port>).Int;
            $key-width         = max($key-width,     wcswidth('#' ~ ~$<key>));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $<comment> {
                $comment-width = max($comment-width, wcswidth(~$<comment>));
            }
        }
    } # $ln #
    #$key-width     += 2;
    #$host-width    += 2;
    $port-width    += 2;
    #$comment-width += 2;
    $key-width = 20 if $key-width < 20;
    $host-width = 70 if $host-width < 70;
    $port-width = 9 if $port-width < 9;
    $input.seek(0, SeekFromBeginning);
    $ln = $input.get;
    while !$input.eof {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
            $output.say: $ln
        } elsif $ln ~~ rx/^ \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            my Str $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, (($port == 0) ?? '' !! ': ' ~ "$port");
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Str:D $port = '';
            with $<port> {
                $port = ': ' ~ ~$<port>;
            }
            my Str $line = sprintf "#%-*s %-3s %-*s %-*s", $key-width - 1, ~$<key>, ~$<type>, $host-width, $host, $port-width, $port;
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } else {
            $output.say: $ln
        }
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/ ^ '#' ** {2 .. ∞} / {
            $output.say: $ln
        } elsif $ln ~~ rx/^ \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Int:D $port = 0;
            with $<port> {
                $port = (~$<port>).Int;
            }
            my Str $line = sprintf "%-*s %-3s %-*s %-*s", $key-width, ~$<key>, ~$<type>, $host-width, $host, $port-width, (($port == 0) ?? '' !! ': ' ~ "$port");
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } elsif $ln ~~ rx/^ \h* '#' \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' || 'sep' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \w+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
            my Str:D $host = ~$<host>;
            $host         .=trim;
            my Str:D $port = '';
            with $<port> {
                $port = ': ' ~ ~$<port>;
            }
            my Str $line = sprintf "#%-*s %-3s %-*s %-*s", $key-width - 1, ~$<key>, ~$<type>, $host-width, $host, $port-width, $port;
            with $<comment> {
                $line ~= " # $<comment>";
            }
            $output.say: $line;
        } else {
            $output.say: $ln
        }
    } # $ln #
    $input.close;
    $output.close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        die "move failed";
    }
} # sub tidy-file( --> Bool) is export #

sub sort-file( --> Bool) is export {
    my Str @file  = "$config/hosts.h_ts".IO.split: "\n",  :close;
    my Str $data = @file.sort( -> $a, $b { (($a.substr(0, 1) eq '#' && $b.substr(0, 1) eq '#') ?? Order::Same !! ((($a.lc leg $b.lc) === Order::Same) ?? $a leg $b !! $a.lc leg $b.lc )) }).join("\n").trim;
    $data ~= "\n" if $data;
    "$config/hosts.h_ts.new".IO.spurt: $data,  :close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        die "move failed";
    }
} # sub sort-file( --> Bool) is export #

sub show-file(Bool:D $colour --> Bool) is export {
    my IO::Handle:D $input  = "$config/hosts.h_ts".IO.open:     :r, :nl-in("\n")   :chomp;
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    my Str $ln;
    if $colour {
        $ln = $input.get;
        while !$input.eof {
            my $actions = LineSyntaxActions;
            #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
            #dd $test;
            my %val = LineSyntax.parse($ln, :enc('UTF-8'), :$actions).made;
            my Str $key             = %val«key»;
            unless $key eq '' || $key eq '#' {
                my %v               = %val«value»;
                my Str:D $type      = %v«type»;
                my Str:D $host      = %v«host»;
                $key-width          = max($key-width,     wcswidth($key));
                $host-width         = max($host-width,    wcswidth($host));
                my Int $port = 0;
                if $type eq 'host' {
                    $port = %v«port».Int;
                    $port-width     = max($port-width,    wcswidth($port));
                }
                with %v«comment» {
                    my Str $comment = %v«comment»;
                    $comment-width  = max($comment-width,    wcswidth($comment));
                }
            }
            $ln = $input.get;
        } # while !$input.eof #
        if $ln {
            my $actions = LineSyntaxActions;
            #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
            #dd $test;
            my %val = LineSyntax.parse($ln, :enc('UTF-8'), :$actions).made;
            my Str $key             = %val«key»;
            unless $key eq '' || $key eq '#' {
                my %v               = %val«value»;
                my Str:D $type      = %v«type»;
                my Str:D $host      = %v«host»;
                $key-width          = max($key-width,     wcswidth($key));
                $host-width         = max($host-width,    wcswidth($host));
                my Int $port = 0;
                if $type eq 'host' {
                    $port = %v«port».Int;
                    $port-width     = max($port-width,    wcswidth($port));
                }
                with %v«comment» {
                    my Str $comment = %v«comment»;
                    $comment-width  = max($comment-width,    wcswidth($comment));
                }
            }
        } # $ln #
        #$key-width     += 2;
        #$host-width    += 2;
        $port-width    += 3;
        #$comment-width += 2;
        $key-width = 20 if $key-width < 20;
        $host-width = 70 if $host-width < 70;
        $port-width = 10 if $port-width < 10;
        my Int:D $width = $key-width + 5 + $host-width + $port-width + 3 + $comment-width;
        $input.seek(0, SeekFromBeginning);
        $ln = $input.get;
        my Int:D $cnt = 0;
        my Bool:D $cond = $cnt %% 2;
        while !$input.eof {
            my $actions = LineSyntaxActions;
            #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
            #dd $test;
            my %val = LineSyntax.parse($ln, :enc('UTF-8'), :$actions).made;
            my Str $key = %val«key»;
            if $key eq '' {
                put ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, %val«value») ~ t.text-reset;
            } elsif %val«key» eq '#' {
                put ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, %val«value») ~ t.text-reset;
            } else {
                my %v = %val«value»;
                my Str:D $type = %v«type»;
                my Str:D $host = %v«host»;
                my Int $port = 0;
                my Str:D $type-spec = '-->';
                if $type eq 'host' {
                    $port = %v«port».Int;
                    $type-spec = ' =>';
                }
                my Str $cline = ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,255,0) ~ sprintf("%-*s", $key-width, $key);
                $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf("%3s", $type-spec);
                if $port > 0 {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf(" %-*s", 3, " : ") ~ t.text-reset;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf("%-*d", $port-width - 3, $port);
                }else {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf(" %-*s", 3, " : ") ~ t.text-reset;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf("%-*s", $port-width - 3, '');
                }
                with %v«comment» {
                    my Str $comment = %v«comment»;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,0,255) ~ sprintf(" # %-*s", $comment-width, $comment);
                } else {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,0,255) ~ sprintf(" # %-*s", $comment-width, '');
                }
                put $cline ~ t.text-reset;
            }
            $ln = $input.get;
            $cnt++;
            $cond = $cnt %% 2;
        } # while !$input.eof #
        if $ln {
            my $actions = LineSyntaxActions;
            #my $test = Line.parse($ln, :enc('UTF-8'), :$actions).made;
            #dd $test;
            my %val = LineSyntax.parse($ln, :enc('UTF-8'), :$actions).made;
            my Str $key = %val«key»;
            my Bool:D $cond = $cnt %% 2;
            if $key eq '' {
                put ($cond ?? t.bg-color(191,191,191) !! t.bg-color(255,255,255)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, %val«value») ~ t.text-reset;
            } elsif %val«key» eq '#' {
                put ($cond ?? t.bg-color(191,191,191) !! t.bg-color(255,255,255)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, %val«value») ~ t.text-reset;
            } else {
                my %v = %val«value»;
                my Str:D $type = %v«type»;
                my Str:D $host = %v«host»;
                my Int $port = 0;
                my Str:D $type-spec = '-->';
                if $type eq 'host' {
                    $port = %v«port».Int;
                    $type-spec = ' =>';
                }
                my Str $cline = ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,255,0) ~ sprintf("%-*s", $key-width, $key);
                $cline ~= t.red ~ sprintf("%3s", $type-spec);
                if $port > 0 {
                    $cline ~= t.bold ~ t.color(255,0,255) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= t.red ~ sprintf(" %-*s", 3, " : ");
                    $cline ~= t.color(255,0,255) ~ sprintf("%-*d", $port-width - 3, $port);
                }else {
                    $cline ~= t.bold ~ t.color(255,0,255) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= t.red ~ sprintf(" %-*s", 3, "   ");
                    $cline ~= t.color(255,0,255) ~ sprintf("%-*s", $port-width - 3, '');
                }
                with %v«comment» {
                    my Str $comment = %v«comment»;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,0,255) ~ sprintf(" # %-*s", $comment-width, $comment);
                } else {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,0,255) ~ sprintf(" # %-*s", $comment-width, '');
                }
                put $cline ~ t.text-reset;
            }
        } # $ln #
        $cnt++;
        $cond = $cnt %% 2;
        put ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,255,0) ~ ' ' x $width ~ t.text-reset;
    } else {
        $ln = $input.get;
        while !$input.eof {
            say $ln;
            $ln = $input.get;
        } # while !$input.eof #
        if $ln {
            say $ln;
        } # $ln #
        ''.say;
    }
    $input.close;
} # sub show-file( --> Bool) is export #

sub backup-db-file(Bool:D $use-windows-formating --> Bool) is export {
    my DateTime $now = DateTime.now;
    my Str:D $time-stamp = $now.Str;
    if $*DISTRO.is-win || $use-windows-formating {
        $time-stamp ~~ tr/./·/;
        $time-stamp ~~ tr/:/./;
    }
    return "$config/hosts.h_ts".IO.copy("$config/hosts.h_ts.$time-stamp".IO);
} # sub backup-db-file(Bool:D $use-windows-formating --> Bool) is export #

sub restore-db-file(IO::Path $restore-from --> Bool) is export {
    with $restore-from {
        my $actions = HostFileActions;
        if $restore-from ~~ :f {
            my @db-file = $restore-from.slurp.split("\n");
            return $restore-from.copy("$config/hosts.h_ts".IO) if HostsFile.parse(@db-file.join("\x0A"), :enc('UTF-8'), :$actions).made;
        }
        return False;
    } else {
        return False;
    }
}

sub backups-menu-restore-db(Bool:D $colour, Bool:D $syntax, Str:D $message = "" --> Bool:D) is export {
    my IO::Path @backups = $config.IO.dir(:test(rx/ ^ 
                                                           'hosts.h_ts.' \d ** 4 '-' \d ** 2 '-' \d ** 2
                                                               [ 'T' \d **2 [ [ '.' || ':' ] \d ** 2 ] ** {0..2} [ [ '.' || '·' ] \d+ 
                                                                   [ [ '+' || '-' ] \d ** 2 [ '.' || ':' ] \d ** 2 || 'z' ]?  ]?
                                                               ]?
                                                           $
                                                         /
                                                       )
                                                );
    #dd @backups;
    my $actions = HostFileActions;
    @backups .=grep: -> IO::Path $fl { 
                                my @file = $fl.slurp.split("\n");
                                HostsFile.parse(@file.join("\x0A"), :enc('UTF-8'), :$actions).made;
                            };
    #dd @backups;
    my $highlight-bg-colour = t.bg-color(0, 0, 107) ~ t.bold;
    my $highlight-fg-colour = t.color(255, 255, 0);
    my @Backups = @backups.map: -> IO::Path $f {
          my %elt = value => $f.Str, backup => $f.basename,
                      perms => symbolic-perms($f, :$colour, :$syntax, :highlight-fg-colour(''),
                                              :fg-colour0(''), :fg-colour1('')),
                      user => uid2username($f.user), group => gid2groupname($f.group),
                      size => format-bytes($f.s), modified => $f.modified.DateTime.local.Str;
          %elt;
    };
    @Backups .=sort( -> %lhs, %rhs { %lhs«value».IO.basename cmp %rhs«value».IO.basename });
    sub row(Int:D $cnt, Int:D $pos, @array,
                                     Bool:D :$colour = False, Bool:D :$syntax = False,
                                     Str:D :$highlight-bg-colour = '',
                                     Str:D :$highlight-fg-colour = '',
                                     Str:D :$bg-colour0 = '',
                                     Str:D :$fg-colour0 = '', 
                                     Str:D :$bg-colour1 = '',
                                     Str:D :$fg-colour1 = ''  --> Str:D) {
        my %r = @array[$cnt];
        if $syntax {
            if %r«value» eq 'cancel' {
                return %r«name» if %r«name»:exists;
                return %r«value»;
            } 
            my Str:D $name = %r«perms» ~ ' ';
            if $cnt == $pos {
                $name ~= $highlight-bg-colour ~ t.color(255, 0, 0)   ~ %r«size»     ~ ' ';
                $name ~= $highlight-bg-colour ~ t.color(255, 255, 0) ~ %r«user»     ~ ' ';
                $name ~= $highlight-bg-colour ~ t.color(255, 255, 0) ~ %r«group»    ~ ' ';
                $name ~= $highlight-bg-colour ~ t.color(0, 0, 255)   ~ %r«modified» ~ ' ';
                $name ~= $highlight-bg-colour ~ t.color(255, 0, 255) ~ %r«backup»   ~ ' ';
            } elsif $cnt %% 2 {
                $name ~= $bg-colour0 ~ t.color(255, 0, 0)   ~ %r«size»     ~ ' ';
                $name ~= $bg-colour0 ~ t.color(255, 255, 0) ~ %r«user»     ~ ' ';
                $name ~= $bg-colour0 ~ t.color(255, 255, 0) ~ %r«group»    ~ ' ';
                $name ~= $bg-colour0 ~ t.color(0, 0, 255)   ~ %r«modified» ~ ' ';
                $name ~= $bg-colour0 ~ t.color(255, 0, 255) ~ %r«backup»   ~ ' ';
            } else {
                $name ~= $bg-colour1 ~ t.color(255, 0, 0)   ~ %r«size»     ~ ' ';
                $name ~= $bg-colour1 ~ t.color(255, 255, 0) ~ %r«user»     ~ ' ';
                $name ~= $bg-colour1 ~ t.color(255, 255, 0) ~ %r«group»    ~ ' ';
                $name ~= $bg-colour1 ~ t.color(0, 0, 255)   ~ %r«modified» ~ ' ';
                $name ~= $bg-colour1 ~ t.color(255, 0, 255) ~ %r«backup»   ~ ' ';
            }
        } elsif $colour {
            if %r«value» eq 'cancel' {
                return %r«name» if %r«name»:exists;
                return %r«value»;
            } 
            my Str:D $name = %r«size» ~ ' ' ~ %r«user» ~ ' ' ~ %r«group» ~ ' ' ~ %r«modified» ~ ' ' ~ %r«backup»;
            if $cnt == $pos {
                return $highlight-bg-colour ~ %r«perms» ~ ' ' ~ $highlight-fg-colour ~ $name;
            } elsif $cnt %% 2 {
                return $bg-colour0          ~ %r«perms» ~ ' ' ~ $fg-colour0          ~ $name;
            } else {
                return $bg-colour1          ~ %r«perms» ~ ' ' ~ $fg-colour1          ~ $name;
            }
        } else {
            if %r«value» eq 'cancel' {
                return %r«name» if %r«name»:exists;
                return %r«value»;
            } 
            my Str:D $name = %r«perms» ~ ' ' ~ %r«size» ~ ' ' ~ %r«user» ~ ' ' ~ %r«group» ~ ' ' ~ %r«modified» ~ ' ' ~ %r«backup»;
            return $name;
        }
    }
    my Str $file = menu(@Backups, $message, :&row, :$colour, :$syntax, :$highlight-bg-colour, :$highlight-fg-colour, :wrap-around);
    return False without $file;
    return False if $file eq '';
    return False if $file eq 'cancel';
    return restore-db-file($file.IO);
} # sub backups-menu-restore-db(Bool:D $colour, Bool:D $syntax, Str:D $message = "" --> Bool:D) is export #

sub list-db-backups(Str:D $prefix,
                    Bool:D $colour is copy,
                    Bool:D $syntax,
                    Regex:D $pattern,
                    Int:D $page-length --> Bool:D) is export {
    $colour = True if $syntax;
    my IO::Path @backups = $config.IO.dir(:test(rx/ ^ 
                                                           'hosts.h_ts.' \d ** 4 '-' \d ** 2 '-' \d ** 2
                                                               [ 'T' \d **2 [ [ '.' || ':' ] \d ** 2 ] ** {0..2} [ [ '.' || '·' ] \d+ 
                                                                   [ [ '+' || '-' ] \d ** 2 [ '.' || ':' ] \d ** 2 || 'z' ]?  ]?
                                                               ]?
                                                           $
                                                         /
                                                       )
                                                );
    #dd @backups;
    my $actions = HostFileActions;
    @backups .=grep: -> IO::Path $fl { 
                                my @file = $fl.slurp.split("\n");
                                HostsFile.parse(@file.join("\x0A"), :enc('UTF-8'), :$actions).made;
                            };
    @backups .=sort;
    my @_backups = @backups.map: -> IO::Path $f {
          my %elt = backup => $f.basename, perms => symbolic-perms($f, :$colour, :$syntax),
                      user => $f.user, group => $f.group, size => $f.s, modified => $f.modified;
          %elt;
      };
    #dd @backups;
    my Str:D @fields = 'perms', 'size', 'user', 'group', 'modified', 'backup';
    my       %defaults;
    my Str:D %fancynames = perms => 'Permissions', size => 'Size',
                             user => 'User', group => 'Group',
                             modified => 'Date Modified', backup => 'Backup';
    sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) {
        my Str:D $value = ~(%row«backup» // '');
        return True if $value.starts-with($prefix, :ignorecase) && $value ~~ $pattern;
        return False;
    } # sub include-row(Str:D $prefix, Regex:D $pattern, Int:D $idx, Str:D @fields, %row --> Bool:D) #
    sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        #dd $indx, $field, $colour, $syntax, @fields;
        if $colour {
            if $syntax { 
                return t.color(0, 255, 255) ~ %fancynames{$field};
            } else {
                return t.color(0, 255, 255) ~ %fancynames{$field};
            }
        } else {
            return %fancynames{$field};
        }
    } # sub head-value(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) #
    sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) {
        return ' ';
    } # sub head-between(Int:D $indx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields --> Str:D) #
    sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        my Str:D $val = ~($value // ''); #`««« assumming $value is a Str:D »»»
        #dd $val, $value, $field;
        if $syntax {
            given $field {
                when 'perms'    { return $val; }
                when 'size'     {
                    my Int:D $size = +$value;
                    return t.color(255, 0, 0) ~ format-bytes($size);
                }
                when 'user'     { return t.color(255, 255, 0) ~ uid2username(+$value);    }
                when 'group'    { return t.color(255, 255, 0) ~ gid2groupname(+$value);   }
                when 'modified' {
                    my Instant:D $m = +$value;
                    my DateTime:D $dt = $m.DateTime.local;
                    return t.color(0, 0, 235) ~ $dt.Str;  
                }
                when 'backup'   { return t.color(255, 0, 255) ~ $val; }
                default         { return t.color(255, 0, 0) ~ $val;   }
            } # given $field #
        } elsif $colour {
            given $field {
                when 'perms'    { return $val; }
                when 'size'     {
                    my Int:D $size = +$value;
                    return t.color(0, 0, 255) ~ format-bytes($size);
                }
                when 'user'     { return t.color(0, 0, 255) ~ uid2username(+$value);    }
                when 'group'    { return t.color(0, 0, 255) ~ gid2groupname(+$value);   }
                when 'modified' {
                    my Instant:D $m = +$value;
                    my DateTime:D $dt = $m.DateTime.local;
                    return t.color(0, 0, 255) ~ $dt.Str;  
                }
                when 'backup'   { return t.color(0, 0, 255) ~ $val;   }
                default         { return t.color(255, 0, 0) ~ $val;   }
            } # given $field #
        } else {
            given $field {
                when 'perms'    { return $val; }
                when 'size'     {
                    my Int:D $size = +$value;
                    return format-bytes($size);
                }
                when 'user'     { return uid2username(+$value);    }
                when 'group'    { return gid2groupname(+$value);   }
                when 'modified' {
                    my Instant:D $m = +$value;
                    my DateTime:D $dt = $m.DateTime.local;
                    return $dt.Str;  
                }
                when 'backup'   { return $val;   }
                default         { return $val;   }
            } # given $field #
        }
    } # sub field-value(Int:D $idx, Str:D $field, $value, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) #
    sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) {
        return ' ';
    } # sub between(Int:D $idx, Str:D $field, Bool:D $colour, Bool:D $syntax, Str:D @fields, %row --> Str:D) #
    sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) {
        if $colour {
            if $syntax { 
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3; # three heading lines. #
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            } else {
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -3;
                return t.bg-color(0, 0, 127) ~ t.bold ~ t.bright-blue if $cnt == -2;
                return t.bg-color(255, 0, 255) ~ t.bold ~ t.bright-blue if $cnt == -1;
                return (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,195,0)) ~ t.bold ~ t.bright-blue;
            }
        } else {
            return '';
        }
    } # sub row-formatting(Int:D $cnt, Bool:D $colour, Bool:D $syntax --> Str:D) #
    return list-by($prefix, $colour, $syntax, $page-length,
                  $pattern, @fields, %defaults, @_backups,
                  :!sort,
                  :&include-row, 
                  :&head-value, 
                  :&head-between,
                  :&field-value, 
                  :&between,
                  :&row-formatting);
} #`««« sub list-db-backups(Str:D $prefix,
                            Bool:D $colour is copy,
                            Bool:D $syntax,
                            Regex:D $pattern,
                            Int:D $page-length --> Bool:D) is export »»»

sub test( --> True) is export {
    #«««
    my $colour = t.color(255, 0, 0);
    my $bg-colour = t.bg-color(0, 0, 255);
    my $bold   = t.bold;
    my $italic = t.italic;
    my $end = t.text-reset;
    my $esc = "\e";
    dd $colour, $bg-colour, $bold, $italic, $end, $esc;
    my Str:D $highlighted = $bg-colour ~ $bold ~ $colour ~ 'Hello out there' ~ $end;
    put $highlighted;
    my Str:D $text = strip-ansi($highlighted);
    put $text;
    dd $highlighted, $text;
    #`«««
    put Sprintf('%30.34s, %30.34s%N%%%N%^*.*s%3$*4$.*3$d', $highlighted, $text, 40, 50, $highlighted);
    put Sprintf('%30.34e, %30.34E%N%%%N%^*.*f%3$*4$.*3$d', 3.14159265, 42E10, 40, 50, 2.71828E-50);
    put Sprintf('%30.34g, %30.34G%N%%%N%^*.*F%3$*4$.*3$d', 3.14159265, 42E100, 40, 50, 2.71828E-50);
    put Sprintf('%30.34f, %30.34f%N%%%N%^*.*F%3$*4$.*3$d', 3.14159265, 42E100, 40, 50, 2.71828E-50);
    put Sprintf('%#30.34b, %#30.34b%N%%%N%#^*.*b%3$#*4$.*3$B', 300, 42, 40, 50, 2);
    put Sprintf('%#30.34o, %#30.34o%N%%%N%#^*.*O%3$#*4$.*3$O', 300, 42, 40, 50, 2);
    put Sprintf('%#30.34x, %#30.34x%N%%%N%#^*.*X%3$#*4$.*3$X', 300, 42, 40, 51, 31);
    put Sprintf('%#30.34u, %#30.34u%N%%%N%#^*.*U%3$#*4$.*3$U', 300, 42, 40, 51, 31);
    put Sprintf('%0#30.34u, %0#30.34u%N%%%N%0#^*.*U%N%3$0#*4$.*3$U', 300, 42, 40, 51, 31);
    put Sprintf('%0#30.34u, %0#30.34u%N%%%N%0#^*.*U%N%3$0#*4$.*3$U', 300, 42, 40, 51, 31, 1, 2, 3);
    #`« uncomment to test exceptions #
    put Sprintf('%0#30.34u, %0#30.34u%N%%%N%0#^*.*U%N%3$0#*4$.*3$U', 300, 42, 40, 'bad', 31);
    BadArg.new(:msg("Testing this")).throw;
    die "Just for fun!";
    #»
    #»»»
    #«
    #put Sprintf('%[*]30.34.33s, %[#]30.34.33s%N%%%N%^[*]*.*.33s%3$[$]*4$.*3$.37d', $highlighted, $text, 40, 50, $highlighted);
    #put Sprintf('%^[%]30.34.30e, %^[@]30.34.30E%N%%%N%^[^]*.*f%T%3$*4$.*3$.30d', 3.14159265, 42E10, 40, 50, 2.71828E-30, :ellipsis('…'));
    #put Sprintf('%^[%]30.34.30e, %^[@]30.34.30E%N%%%N%^[^]*.*.20f%T%3$^[+]*4$.*3$.30d', 3.14159265, 42E10, 40, 50, 2.71828E-30, :ellipsis('…'));
    #put Sprintf('%^[^]*.*.*f, %T%4$^[+]*1$.*2$.*3$d', 24, 6, 20, 2.71828, :ellipsis('…'));
    #»
    put Sprintf('%^[*]3$*4$.*3$.30d', 3.14159265, 42E10, 40, 50, 2.71828E-30, :ellipsis('…')); # should throw exception #
    Sprintf('%3$^[*%$]*4$.*3$.30d', 3.14159265, 42E10, 40, 50, 2.71828E-30, :ellipsis('…')); # should also throw #
    #put Sprintf('%3$^[*#]*4$.*3$.30d', 3.14159265, 42E10, 40, 50, 2.71828E-30, :ellipsis('…')); # should throw exception #
    #`««
    put Sprintf('%30.34g, %30.34G%N%%%N%^*.*F%3$*4$.*3$d', 3.14159265, 42E100, 40, 50, 2.71828E-50);
    put Sprintf('%30.34f, %30.34f%N%%%N%^*.*F%3$*4$.*3$d', 3.14159265, 42E100, 40, 50, 2.71828E-50);
    put Sprintf('%#30.34b, %#30.34b%N%%%N%#^*.*b%3$#*4$.*3$B', 300, 42, 40, 50, 2);
    put Sprintf('%#30.34o, %#30.34o%N%%%N%#^*.*O%3$#*4$.*3$O', 300, 42, 40, 50, 2);
    put Sprintf('%#30.34x, %#30.34x%N%%%N%#^*.*X%3$#*4$.*3$X', 300, 42, 40, 51, 31);
    put Sprintf('%#30.34u, %#30.34u%N%%%N%#^*.*U%3$#*4$.*3$U', 300, 42, 40, 51, 31);
    put Sprintf('%0#30.34u, %0#30.34u%N%%%N%0#^*.*U%N%3$0#*4$.*3$U', 300, 42, 40, 51, 31);
    put Sprintf('%0#30.34u, %0#30.34u%N%%%N%0#^*.*U%N%3$0#*4$.*3$U', 300, 42, 40, 51, 31, 1, 2, 3);
    #»»
    
    my $test-number-of-chars = 0;
    my $test-number-of-visible-chars = 0;

    sub test-number-of-chars(Int:D $number-of-chars, Int:D $number-of-visible-chars --> Bool:D) {
        $test-number-of-chars         = $number-of-chars;
        $test-number-of-visible-chars = $number-of-visible-chars;
        return True
    }

    put Sprintf('%30.14.14s, %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s', ${ arg => $highlighted, ref => $text }, $text, 30, 14, $highlighted, 13, :number-of-chars(&test-number-of-chars), :ellipsis('…'));
    dd $test-number-of-chars,  $test-number-of-visible-chars;
    put Sprintf('%30.14.14s,  testing %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s', $[ $highlighted, $text ], $text, 30, 14, $highlighted, 13, 13, :number-of-chars(&test-number-of-chars), :ellipsis('…'));
    dd $test-number-of-chars,  $test-number-of-visible-chars;
    Printf('%30.14.14s,  testing %30.14.13s%N%%%N%^*.*s%3$*4$.*3$.*6$d%N%2$^[&]*3$.*4$.*6$s%T%1$[*]^100.*4$.99s%N%1$[!]*4$.*3$.*7$s%N', $[ $highlighted, $text ], $text, 30, 14, $highlighted, 13, 13, :number-of-chars(&test-number-of-chars), :ellipsis('…'));
    dd $test-number-of-chars,  $test-number-of-visible-chars;
    CATCH {
        when BadArg {
            .WHAT.^name.say; .message; .say; .resume;
        }
        when ArgParityMissMatch {
            .WHAT.^name.say; .message; .say; .resume;
        }
        when FormatSpecError {
            .WHAT.^name.say; .message; .say; .resume;
        }
        when X::AdHoc {
            .WHAT.^name.say; .message; .say; .resume;
        }
        when X::TypeCheck::Assignment {
            .WHAT.^name.say; .message; .say; .resume;
        }
        default {
            .WHAT.^name.say; .message; .say; .resume;
        }
    }
} # sub test( --> True) is export #

#`«««
    ############################################
    #                                          #
    #   The actual work horses of the library  #
    #                                          #
    ############################################
#»»»

sub resolve-alias(Str:D $key --> Str:D) {
    my Str:D $KEY    = $key;
    my %val          = %the-lot{$KEY};
    my Str:D $host   = %val«host»;
    my Str:D $type   = %val«type»;
    while $type eq 'alias' {
        $KEY         = $host;
        unless %the-lot{$KEY}:exists {
            $*ERR.say: "could not resolve $key dangling alias";
            return '';
        }
        %val         = %the-lot{$KEY};
        $host        = %val«host»;
        $type        = %val«type»;
    }
    unless $type eq 'host' {
        $*ERR.say: "could not resolve $key dangling alias did not resolve to a valid host entry.";
        $KEY = '';
    }
    return $KEY;
} # sub resolve-alias(Str:D $key --> Str:D) #

=begin pod

=head3 ssh(…)

=begin code :lang<raku>

sub ssh(Str:D $key --> Bool) is export 

=end code

L<Top of Document|#table-of-contents>

=end pod

sub ssh(Str:D $key --> Bool) is export {
    if %the-lot{$key}:exists {
        my Str:D $type    = %the-lot{$key}«type»;
        my Str:D $KEY = $key;
        if $type eq 'alias' {
            $KEY = resolve-alias($key);
            die "bad key: $key"  if $KEY eq '';
        }
        my Str $host      = %the-lot{$KEY}«host»;
        my Int $port      = %the-lot{$KEY}«port»;
        say join ' ', 'ssh', '-p', $port, $host;
        my Proc $r = run 'ssh', '-p', $port, $host;
        if $r.exitcode == 0 {
            return True;
        }
        die "non-zero exit code";
    }
    die "key $key not found";
}

=begin pod

=head3 ping(…)

=begin code :lang<raku>

sub ping(Str:D $key --> Bool) is export 

=end code

L<Top of Document|#table-of-contents>

=end pod

sub ping(Str:D $key --> Bool) is export {
    if %the-lot{$key}:exists {
        my Str:D $type    = %the-lot{$key}«type»;
        my Str:D $KEY = $key;
        if $type eq 'alias' {
            $KEY = resolve-alias($key);
            die "bad key: $key"  if $KEY eq '';
        }
        my Str $host      = %the-lot{$KEY}«host»;
        my Int $port      = %the-lot{$KEY}«port»;
        $host ~~ s/^^ <-[\@]>+ '@' //;
        say join ' ', 'ping', $host;
        my Proc $r = run 'ping', $host;
        if $r.exitcode == 0 {
            return True;
        }
        die "non-zero exit code";
    }
    die "key $key not found";
}

=begin pod

=head3 _get(…)

=begin code :lang<raku>

multi sub _get('home', Str:D $key,
                Bool :r(:$recursive) = False,
                Str:D :$to = '.',
                *@args --> Bool) is export 

=end code

L<See sc get home|#sc-get-home>

L<Top of Document|#table-of-contents>

=end pod

multi sub _get('home', Str:D $key,
                Bool :r(:$recursive) = False,
                Str:D :$to = '.',
                *@args --> Bool) is export {
    if %the-lot{$key}:exists {
        my Str:D $type    = %the-lot{$key}«type»;
        my Str:D $KEY = $key;
        if $type eq 'alias' {
            $KEY = resolve-alias($key);
            die "bad key: $key"  if $KEY eq '';
        }
        my Str $host      = %the-lot{$KEY}«host»;
        my Int $port      = %the-lot{$KEY}«port»;
        my Int:D $result = 0;
        for @args -> $arg {
            if $recursive {
                ('scp', '-r', '-P', $port, "$host:$arg", '.').join(' ').say;
                my Proc $r = run 'scp', '-r', '-P', $port, "$host:$arg", $to;
                $result +&= $r.exitcode;
            } else {
                ('scp', '-P', $port, "$host:$arg", '.').join(' ').say;
                my Proc $r = run 'scp', '-P', $port, "$host:$arg", $to;
                $result +&= $r.exitcode;
            }
        }
        if $result == 0 {
            return True;
        } else {
            die "non-zero exit code";
        }
    }
    die "key $key not found";
} # multi sub get('home', Str:D $key, Bool $recursive, *@args --> Bool) is export #

=begin pod

=head3 _put(…)

=begin code :lang<raku>

multi sub _put('home', Str:D $key,
                Bool :r(:$recursive) = False,
                Str:D :$to = '',
                *@args --> Bool) is export 

=end code

L<Top of Document|#table-of-contents>

=end pod

multi sub _put('home', Str:D $key,
                Bool :r(:$recursive) = False,
                Str:D :$to = '',
                *@args --> Bool) is export {
    if %the-lot{$key}:exists {
        my Str:D $type    = %the-lot{$key}«type»;
        my Str:D $KEY = $key;
        if $type eq 'alias' {
            $KEY = resolve-alias($key);
            die "bad key: $key"  if $KEY eq '';
        }
        my Str $host      = %the-lot{$KEY}«host»;
        my Int $port      = %the-lot{$KEY}«port»;
        if $recursive {
            ('scp', '-r', '-P', $port, |@args, "$host:$to").join(' ').say;
            my Proc $r = run 'scp', '-r', '-P', $port, |@args, "$host:$to";
            if $r.exitcode == 0 {
                return True;
            }
            die "non-zero exit code";
        } else {
            ('scp', '-P', $port, |@args, "$host:$to").join(' ').say;
            my Proc $r = run 'scp', '-P', $port, |@args, "$host:$to";
            if $r.exitcode == 0 {
                return True;
            }
            die "non-zero exit code";
        }
    }
    die "key $key not found";
} # multi sub put('home', Str:D $key, Bool $recursive, *@args --> Bool) is export #

