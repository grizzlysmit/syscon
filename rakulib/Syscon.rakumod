unit module Syscon:ver<0.1.0>:auth<Francis Grizzly Smit (grizzlysmit@smit.id.au)>;

use Terminal::ANSI::OO :t;
use Terminal::Width;
use Terminal::WCWidth;

# the home dir #
constant $home is export = %*ENV<HOME>.Str();

# config files
constant $config is export = "$home/.local/share/syscon";

if $config.IO !~~ :d {
    $config.IO.mkdir();
}

# The config files to test for #
constant @config-files is export = qw{hosts.h_ts editors};

my Str @guieditors;

sub generate-configs(Str $file) returns Bool:D {
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
                    when 'editors' {
                        $content = q:to/END/;
                            # these editors are gui editors
                            # you can define multiple lines like these 
                            # and the system will add to an array of strings 
                            # to treat as guieditors (+= is prefered but = can be used).  
                            guieditors  +=  gvim
                            guieditors  +=  xemacs
                            guieditors  +=  gedit
                            guieditors  +=  kate

                        END
                        for <gvim xemacs kate gedit> -> $guieditor {
                            @guieditors.append($guieditor);
                        }
                        for @guieditors -> $guieditor {
                            $content ~= "\n        guieditors  +=  $guieditor";
                        }
                    } # when 'editors' #
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
        when 'editors' {
            my Str $content = q:to/END/;
                # these editors are gui editors
                # you can define multiple lines like these 
                # and the system will add to an array of strings 
                # to treat as guieditors (+= is prefered but = can be used).  
                guieditors  +=  gvim
                guieditors  +=  xemacs
                guieditors  +=  gedit
                guieditors  +=  kate

            END
            $content .=trim-trailing;
            for <gvim xemacs kate gedit> -> $guieditor {
                @guieditors.append($guieditor);
            }
            for @guieditors -> $guieditor {
                $content ~= "\n        guieditors  +=  $guieditor";
            }
            my Bool $r = $fd.put: $content;
            "could not write $config/$file".say if ! $r;
            $result ?&= $r;
        } # when 'editors' #
    } # given $file #
    my Bool $r = $fd.close;
    "error closing file: $config/$file".say if ! $r;
    $result ?&= $r;
    return $result;
} # sub generate-configs(Str $file) returns Bool:D #


my Bool:D $please-edit = False;
for @config-files -> $file {
    my Bool $result = True;
    if "$config/$file".IO !~~ :e || "$config/$file".IO.s == 0 {
        $please-edit = True;
        if "/etc/skel/.local/share/syscon/$file".IO ~~ :f {
            try {
                CATCH {
                    when X::IO::Copy { 
                        "could not copy /etc/skel/.local/share/syscon/$file -> $config/$file".say;
                        my Bool $r = generate-configs($file); 
                        $result ?&= $r;
                    }
                }
                my Bool $r = "/etc/skel/.local/share/syscon/$file".IO.copy("$config/$file".IO, :createonly);
                if $r {
                    "copied /etc/skel/.local/share/syscon/$file -> $config/$file".say;
                } else {
                    "could not copy /etc/skel/.local/share/syscon/$file -> $config/$file".say;
                }
                $result ?&= $r;
            }
        } else {
            my Bool $r = generate-configs($file);
            "generated $config/$file".say if $r;
            $result ?&= $r;
        }
    }
} # for @config-files -> $file # 

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
    token TOP           {  [ <line> [ \v+ <line> ]* \v* ]? }
    token line          {  [ <host-line> || <alias> ] }
    token host-line     { ^^ <key> \h+ '=>' <host-port> [ '#' \h* <comment> \h* ]? $$ }
    token alias         { ^^ <key> \h+ '-->' \h+ <target=.key> \h+ [ '#' \h* <comment> \h* ]? $$ }
    token comment       { <-[\n]>* }
}

class HostFileActions does KeyActions does HostPortActions {
    method line($/) {
        my %val;
        if $/<host-line> {
            %val = $/<host-line>.made;
        } elsif $/<alias> {
            %val = $/<alias>.made;
        }
        make %val;
    }
    method comment($/)   { make $/<comment>.made }
    method host-line   ($/)  {
        my %val = $/<host-port>.made;
        %val«type» = 'host';
        if $/<comment> {
            my Str $com = ~($/<comment>).trim;
            %val«comment» = $com;
        }
        make $/<key>.made => %val;
    }
    method alias  ($/) {
        my %val =  type => 'alias', host => $/<target>.made;
        if $/<comment> {
            my $com = ~($/<comment>).trim;
            #$com ~~ s:g/ $<closer> = [ '}' ] /\\$<closer>/;
            %val«comment» = $com;
        }
        make $/<key>.made => %val;
    }
    method target ($/) { make $/<key>.made }
    method TOP($match) {
        my %lines = $match<line>.map: *.made;
        $match.make: %lines;
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

# the editor to use #
my Str $editor = '';
if %*ENV<GUI_EDITOR>:exists {
    $editor = %*ENV<GUI_EDITOR>.Str();
} elsif %*ENV<VISUAL>:exists {
    $editor = %*ENV<VISUAL>.Str();
} elsif %*ENV<EDITOR>:exists {
    $editor = %*ENV<EDITOR>.Str();
} else {
    my Str $gvim = qx{/usr/bin/which gvim 2> /dev/null };
    my Str $vim  = qx{/usr/bin/which vim  2> /dev/null };
    my Str $vi   = qx{/usr/bin/which vi   2> /dev/null };
    if $gvim.chomp {
        $editor = $gvim.chomp;
    } elsif $vim.chomp {
        $editor = $vim.chomp;
    } elsif $vi.chomp {
        $editor = $vi.chomp;
    }
}
if $please-edit {
    edit-configs();
    exit 0;
}

#`«««
    ###############################################################################
    #                                                                             #
    #            grammars for parsing the `editors` configuration file            #
    #                                                                             #
    ###############################################################################
#»»»

grammar Editors {
    regex TOP              { [ <line> [ \v+ <line> ]* \v* ]? }
    regex line             { [ <white-space-line> || <comment-line> || <config-line> ] }
    regex white-space-line { ^^ \h* $$ }
    regex comment-line     { ^^ \h* '#' <-[\n]>* $$ }
    regex config-line      { ^^ \h* 'guieditors' \h* '+'? '=' \h* <editor> \h* [ '#' <comment> \h* ]? $$ }
    regex editor           { <path> '/' <editor-name> || <editor-name> }
    regex comment          { <-[\n]>* }
    regex path             { <lead-in>  <path-segments>? }
    regex lead-in          { [ '/' | '~' | '~/' ] }
    regex path-segments    { <path-segment> [ '/' <path-segment> ]* '/'? }
    regex path-segment     { \w+ [ [ '-' || \h || '+' || ':' || '@' || '=' || '!' || ',' || '&' || '&' || '%' || '.' ]+ \w* ]* }
    regex editor-name      { \w+ [ [ '-' || \h || '+' || ':' || '@' || '=' || '!' || ',' || '&' || '&' || '%' || '.' ]+ \w* ]* }
}

class EditorsActions {
    method white-space-line($/) {
        my %wspln = type => 'white-space-line', value => ~$/;
        make %wspln;
    }
    method comment-line($/) {
        my %comln = type => 'comment-line', value => ~$/;
        make %comln;
    }
    method editor-name($/) {
        my $edname = ~$/;
        make $edname;
    }
    method lead-in($/) {
        my $leadin = ~$/;
        make $leadin;
    }
    method path-segment($/) {
        my $ps = ~$/;
        make $ps;
    }
    method path-segments($/) {
        my @path-seg = $/<path-segment>».made;
        make @path-seg.join('/');
    }
    method path($/) {
        my Str $ed-path = $/<lead-in>.made ~ $/<path-segments>.made;
        make $ed-path;
    }
    method editor($/) {
        my $ed-name;
        if $/<path> {
            $ed-name = $/<path>.made ~ '/' ~ $/<editor-name>.made;
        } else {
            $ed-name = $/<editor-name>.made;
        }
        make $ed-name;
    }
    method comment($/) {
        my $comm = ~$/;
        make $comm;
    }
    method config-line($/) {
        my %cfg-line = type => 'config-line', value => $/<editor>.made;
        if $/<comment> {
            my $com = ~($/<comment>).trim;
            %cfg-line«comment» = $com;
        }
        make %cfg-line;
    }
    method line($/) {
        my %ln;
        if $/<white-space-line> {
            %ln = $/<white-space-line>.made;
        } elsif $/<comment-line> {
            %ln = $/<comment-line>.made;
        } elsif $/<config-line> {
            %ln = $/<config-line>.made;
        }
        make %ln;
    }
    method TOP($made) {
        my @top = $made<line>».made;
        $made.make: @top;
    }
} # class EditorsActions #

#`«««
    #########################################################
    #*******************************************************#
    #*                                                     *#
    #*    This grammar is for parse the usage string       *#
    #*                                                     *#
    #*******************************************************#
    #########################################################
#»»»


grammar Paths {
    regex path          { [ <absolute-path> || <relative-path> ] }
    regex absolute-path { <lead-in>  <path-segments>? }
    regex lead-in       { [ '/' || '~/' || '~' ] }
    regex relative-path { <path-segments> }
    regex path-segments { <path-segment> [ '/' <path-segment> ]* '/' }
    regex path-segment  { \w+ [ [ '-' || '+' || ':' || '@' || '=' || ',' || '%' || '$' || '.' ]+ \w+ ]* }
}

role PathsActions {
    method lead-in($/) {
        my $leadin = ~$/;
        make $leadin;
    }
    method path($/) {
        my Str $abs-rel-path;
        if $/<absolute-path> {
            $abs-rel-path = $/<absolute-path>.made;
        } elsif $/<relative-path> {
            $abs-rel-path = $/<relative-path>.made;
        }
        make $abs-rel-path;
    }
    method absolute-path($/) {
        my Str $abs-path = $/<lead-in>.made;
        if $/<path-segments> {
            $abs-path ~= $/<path-segments>.made;
        }
        make $abs-path;
    }
    method relative-path($/) {
        my Str $rel-path = '';
        if $/<path-segments> {
            $rel-path ~= $/<path-segments>.made;
        }
        make $rel-path;
    }
    method path-segment($/) {
        my $ps = ~$/;
        make $ps;
    }
    method path-segments($/) {
        my @pss = $/<path-segment>».made;
        make @pss.join('/');
    }
} # role PathsActions #

grammar UsageStr is Paths {
    token TOP               { ^ 'Usage:' [ \v+ <usage-line> ]+ \v* $ }
    token usage-line        { ^^ \h* <prog> <fixed-args-spec> <pos-spec> <optionals-spec> <slurpy-array-spec> <options-spec> <slurpy-hash-spec> \h* $$ }
    token fixed-args-spec   { [ \h* <fixed-args> ]? }
    token pos-spec          { [ \h* <positional-args> ]? }
    regex optionals-spec    { [ \h* <optionals> ]? }
    regex slurpy-array-spec { [ \h* <slurpy-array> ]? }
    token options-spec      { [ \h* <options> ]? }
    token slurpy-hash-spec  { [ \h* <slurpy-hash> ]? }
    token prog              { [ <prog-name> <!before [ '/' || '~/' || '~' ] > || <path> <prog-name> ] }
    token prog-name         { \w+ [ [ '-' || '+' || ':' || '@' || '=' || ',' || '%' || '.' ]+ \w+ ]* }
    token fixed-args        { [ <fixed-arg> [ \h+ <fixed-arg> ]* ]? }
    token fixed-arg         {  \w+ [ [ '-' || '+' || ':' || '.' ]+ \w+ ]* }
    regex positional-args   { [ <positional-arg> [ \h+ <positional-arg> ]* ]? }
    regex positional-arg    { '<' \w+ [ '-' \w+ ]* '>' }
    regex optionals         { [ <optional> [ \h+ <optional> ]* ] }
    regex optional          { '[<' [ \w+ [ '-' \w+ ]* ] '>]' }
    regex slurpy-array      { [ '[<' [ \w+ [ '-' \w+ ]* ] '>' \h '...' ']' ] }
    regex options           { [ <option> [ \h+ <option> ]* ] }
    regex option            { [ <int-opt> || <other-opt> || <bool-opt> ] }
    regex int-opt           { [ '[' <opts> '[=Int]]' ] }
    regex other-opt         { [ '[' <opts> '=<' <type> '>]' ] }
    regex bool-opt          { [ '[' <opts> ']' ] }
    token opts              { <opt> [ '|' <opt> ]* }
    regex opt               { [ <long-opt> || <short-opt> ] }
    regex short-opt         { [ '-' \w ] }
    regex long-opt          { [ '--' \w ** {2 .. Inf} [ '-' \w+ ]* ] }
    regex type              { [ 'Str' || 'Num' || 'Rat' || 'Complex' || [ \w+ [ '-' \w+ ]* ] ] }
    regex slurpy-hash       { [ '[--<' [ \w+ [ '-' \w+ ]* ] '>=...]' ] }
}

class UsageStrActions does PathsActions {
    method prog($/) {
        my $prog;
        if $/<path> {
            $prog = $/<path>.made ~ '/' ~ $/<prog-name>.made;
        } else {
            $prog = $/<prog-name>.made;
        }
        make $prog;
    }
    method prog-name($/) {
        my $prog-name = ~$/;
        make $prog-name;
    }
    method fixed-args-spec($/) {
        my @fixed-args-spec;
        if $/<fixed-args> {
            @fixed-args-spec = $/<fixed-args>.made;
        }
        make @fixed-args-spec;
    }
    method fixed-args($/) {
        my @fixed-args = $/<fixed-arg>».made;
        make @fixed-args;
    }
    method fixed-arg($/) {
        my $fixed-arg = ~$/;
        make $fixed-arg;
    }
    method pos-spec($/) {
        my @pos-spec;
        if $/<positional-args> {
            @pos-spec = $/<positional-args>.made;
        }
        make @pos-spec;
    }
    method positional-args($/) {
        my @positional-args = $/<positional-arg>».made;
        make @positional-args;
    }
    method positional-arg($/) {
        my $positional-arg = ~$/;
        make $positional-arg;
    }
    method optionals-spec($/) {
        my @optionals-spec;
        if $/<optionals> {
            @optionals-spec = $/<optionals>.made;
        }
        make @optionals-spec;
    }
    method optionals($/) {
        my @optionals = $/<optional>».made;
        make @optionals;
    }
    method optional($/) {
        my $optional = ~$/;
        make $optional;
    }
    method slurpy-array-spec($/) {
        my $slurpy-array-spec = '';
        if $/<slurpy-array> {
            $slurpy-array-spec = $/<slurpy-array>.made;
        }
        make $slurpy-array-spec;
    }
    method slurpy-array($/) {
        my $slurpy-array = ~$/;
        make $slurpy-array;
    }
    method options-spec($/) {
        my @options-spec;
        if $/<options> {
            @options-spec = $/<options>.made;
        }
        make @options-spec;
    }
    method options($/) {
        my @options = $/<option>».made;
        make @options;
    }
    method option($/) {
        my $option;
        if $/<int-opt> {
            $option = $/<int-opt>.made;
        } elsif $/<other-opt> {
            $option = $/<other-opt>.made;
        } elsif $<bool-opt> {
            $option = $/<bool-opt>.made;
        }
        make $option;
    }
    method int-opt($/) {
        my $int-opt = '[' ~ $/<opts>.made ~ '[=Int]]';
        make $int-opt;
    }
    method other-opt($/) {
        my $other-opt = '[' ~ $/<opts>.made ~ '=<' ~ $/<type> ~ '>]';
        make $other-opt;
    }
    method bool-opt($/) {
        my $bool-opt = '[' ~ $/<opts>.made ~ ']';
        make $bool-opt;
    }
    method opts($/) {
        my @opts = $/<opt>».made;
        make @opts.join('|');
    }
    method opt($/) {
        my $opt;
        if $/<short-opt> {
            $opt = $/<short-opt>.made;
        } elsif $/<long-opt> {
            $opt = $/<long-opt>.made;
        }
        make $opt;
    }
    method short-opt($/) {
        my $short-opt = ~$/;
        make $short-opt;
    }
    method long-opt($/) {
        my $long-opt = ~$/;
        make $long-opt;
    }
    method type($/) {
        my $type = ~$/;
        make $type;
    }
    method slurpy-hash-spec($/) {
        my $slurpy-hash-spec = '';
        if $/<slurpy-hash> {
            $slurpy-hash-spec = $/<slurpy-hash>.made;
        }
        make $slurpy-hash-spec;
    }
    method slurpy-hash($/) {
        my $slurpy-hash = ~$/;
        make $slurpy-hash;
    }
    method usage-line($/) {
        my %line = prog => $/<prog>.made, fixed-args => $/<fixed-args-spec>.made,
        positional-args => $/<pos-spec>.made, optionals => $/<optionals-spec>.made,
        slurpy-array => $/<slurpy-array-spec>.made, options => $/<options-spec>.made,
        slurpy-hash => $/<slurpy-hash-spec>.made;
        my %usage-line = kind => 'usage-line', value => %line;
        make %usage-line;
    }
    method TOP($made) {
        my %u   = kind => 'usage', value => 'Usage:';
        my @top = %u, |($made<usage-line>».made);
        $made.make: @top;
    }
} # class UsageStrActions #

my Str  @lines     = slurp("$config/hosts.h_ts").split("\n").grep({ !rx/^ \h* '#' .* $/ }).grep({ !rx/^ \h* $/ });
#dd @lines;
#my Str  %the-hosts = @lines.map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep({ !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / }).map: { my ($key, $value) = $_.split(rx/ \s*  '=>' \s* /, 2); my $e = $key => $value; $e };
#my Hash %the-lot   = @lines.grep({ !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / }).map: { my $e = $_; ($e ~~ rx/^ \s* $<key> = [ \w+ [ [ '.' || '-' || '@' || '+' ]+ \w* ]* ] \s* '=>' \s* $<host> = [ <-[ # ]>+ ] \s* [ '#' \s* $<comment> = [ .* ] ]?  $/) ?? (~$<key> => { value => (~$<host>).trim, comment => ($<comment> ?? ~$<comment> !! Str), }) !! { my ($key, $value) = $_.split(rx/ \s*  '=>' \s* /, 2); my $r = $key => $value; $r } };
my $actions = HostFileActions;
#my $test = HostsFile.parse(@lines.join("\x0A"), :enc('UTF-8'), :$actions).made;
#dd $test, $?NL;
my %the-lot = |(HostsFile.parse(@lines.join("\x0A"), :enc('UTF-8'), :$actions).made);
#my Hash %the-lot = $test.List;
#my Hash %the-lot   = HostsFile.parse(@lines.join("\n"), actions  => HostFileActions.new).made;

# The default name of the gui editor #
my $edactions = EditorsActions;
my @editors-file = "$config/editors".IO.slurp.split("\n");
#dd @editors-file;
#my $edtest = Editors.parse(@editors-file.join("\x0A"), :enc('UTF-8'), :actions($edactions)).made;
#dd $edtest;
my @GUIEDITORS = Editors.parse(@editors-file.join("\x0A"), :enc('UTF-8'), :actions($edactions)).made;
my @gui-editors = @GUIEDITORS.grep( -> %l { %l«type» eq 'config-line' } ).map: -> %ln { %ln«value»; };
#my Str @gui-editors = slurp("$config/editors").split("\n").map( { my Str $e = $_; $e ~~ s/ '#' .* $$ //; $e } ).map( { $_.trim() } ).grep: { !rx/ [ ^^ \s* '#' .* $$ || ^^ \s* $$ ] / };
my Str $gui-editor = "";
#my Str @guieditors;
#@gui-editors.raku.say;
if @gui-editors {
    #@gui-editors.raku.say;
    for @gui-editors -> $geditor {
        if !@guieditors.grep: { $geditor } {
            my Str $guieditor = $geditor;
            $guieditor .=trim;
            @guieditors.append($guieditor);
        }
    }
}
if %*ENV<GUI_EDITOR>:exists {
    my Str $guieditor = ~%*ENV<GUI_EDITOR>;
    if ! @guieditors.grep( { $_ eq $guieditor.IO.basename } ) {
        @guieditors.prepend($guieditor.IO.basename);
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


sub valid-key(Str:D $key --> Bool) is export {
    my $actions = KeyActions;
    my Str $match = KeyValid.parse($key, :rule('key'), :enc('UTF-8'), :$actions).made;
    without $match {
        return False;
    }
    return $key eq $match;
}


sub edit-configs() returns Bool:D is export {
    if $editor {
        my $option = '';
        my @args;
        my $edbase = $editor.IO.basename;
        if $edbase eq 'gvim' {
            $option = '-p';
            @args.append('-p');
        }
        my Str $cmd = "$editor $option ";
        @args.append(|@config-files);
        for @config-files -> $file {
            $cmd ~= "'$config/$file' ";
        }
        $cmd ~= '&' if @guieditors.grep: { rx/ ^^ $edbase $$ / };
        chdir($config.IO);
        #my $proc = run( :in => '/dev/tty', :out => '/dev/tty', :err => '/dev/tty', $editor, |@args);
        my $proc = run($editor, |@args);
        return $proc.exitcode == 0 || $proc.exitcode == -1;
    } else {
        "no editor found please set GUI_EDITOR, VISUAL or EDITOR to your preferred editor.".say;
        "e.g. export GUI_EDITOR=/usr/bin/gvim".say;
        return False;
    }
}

sub list-keys(Str $prefix, Regex:D $pattern --> Array[Str]) is export {
    my Str @keys;
    for %the-lot.keys -> $key {
        if $key.starts-with($prefix, :ignorecase) && $key ~~ $pattern {
            @keys.push($key);
        }
    }
    return @keys;
}

sub say-list-keys(Str $prefix, Bool:D $colour, Regex:D $pattern, Int:D $page-length --> Bool:D) is export {
    my @keys = list-keys($prefix, $pattern).sort: { .lc };
    my Int:D $key-width        = 0;
    my Int:D $comment-width    = 0;
    my Bool:D $comment-present = False;
    for @keys -> $key {
        my %val = %the-lot{$key};
        my Str $comment = %val«comment»;
        $key-width           = max($key-width,     wcswidth($key));
        with $comment {
            $comment-width   = max($comment-width, wcswidth($comment));
            $comment-present = True;
        }
    }
    $key-width      += 2;
    $comment-width  += 2;
    my Int:D $width  = 0;
    if $comment-present {
        $width       = $key-width + $comment-width + 3;
    } else {
        $width       = $key-width;
    }
    my Int:D $cnt = 0;
    if $colour {
        if $comment-present {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s # %-*s", $key-width, 'key', $comment-width, 'comment') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ ('=' x $width) ~ t.text-reset;
            $cnt++;
        } else {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $key-width, 'key') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ ('=' x $width) ~ t.text-reset;
            $cnt++;
        }
    } else {
        if $comment-present {
            printf "%-*s # %-*s\n", $key-width, 'key', $comment-width, 'comment';
            say '=' x $width;
        } else {
            printf "%-*s\n", $key-width, 'key';
            say '=' x $width;
        }
    }
    for @keys -> $key {
        my %val = %the-lot{$key};
        my Str $comment = %val«comment»;
        with $comment {
            if $colour {
                put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s # %-*s", $key-width, $key, $comment-width, $comment) ~ t.text-reset;
                $cnt++;
            } else {
                printf "%-*s # %-*s\n", $key-width, $key, $comment-width, $comment;
                $cnt++;
            }
        } else {
            if $comment-present {
                $comment = '';
                if $colour {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s # %-*s", $key-width, $key, $comment-width, $comment) ~ t.text-reset;
                    $cnt++;
                } else {
                    printf "%-*s # %-*s\n", $key-width, $key, $comment-width, $comment;
                    $cnt++;
                }
            } else {
                if $colour {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $key-width, $key) ~ t.text-reset;
                    $cnt++;
                } else {
                    $key.say;
                    $cnt++;
                }
            }
        }
        if $cnt % $page-length == 0 {
            if $colour {
                if $comment-present {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s # %-*s", $key-width, 'key', $comment-width, 'comment') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ ('=' x $width) ~ t.text-reset;
                    $cnt++;
                } else {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $key-width, 'key') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ ('=' x $width) ~ t.text-reset;
                    $cnt++;
                }
            } else {
                if $comment-present {
                    say '=' x $width;
                    printf "%-*s # %-*s\n", $key-width, 'key', $comment-width, 'comment';
                    say '=' x $width;
                } else {
                    say '=' x $width;
                    printf "%-*s\n", $key-width, 'key';
                    say '=' x $width;
                }
            }
        } # if $cnt % $page-length == 0 #
    } # for @keys -> $key #
    if $colour {
        if $comment-present {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s   %-*s", $key-width, '', $comment-width, '') ~ t.text-reset;
            $cnt++;
        } else {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $key-width, '') ~ t.text-reset;
            $cnt++;
        }
    } else {
        if $comment-present {
            printf("%-*s   %-*s\n", $key-width, '', $comment-width, '');
        } else {
            ''.say;
        }
    }
    return True;
} # sub say-list-keys(Str $prefix, Bool:D $colour, Regex:D $pattern, Int:D $page-length --> Bool:D) is export #

sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ' --> Str) {
    my Str $result = $text;
    $width -= wcswidth($result);
    $width = $width div wcswidth($fill);
    my Int:D $w  = $width div 2;
    $result = $fill x $w ~ $result ~ $fill x ($width - $w);
    return $result;
} # sub centre(Str:D $text, Int:D $width is copy, Str:D $fill = ' ' --> Str) #

sub left(Str:D $text, Int:D $width, Str:D $fill = ' ', Str:D :$ref = $text --> Str) {
    my Int:D $w  = wcswidth($ref);
    my Int:D $l  = ($width - $w).abs;
    my Str:D $result = $text ~ ($fill x $l);
    return $result;
} # sub left(Str:D $text, Int:D $width is copy, Str:D $fill = ' ', Str:D :$ref = $text --> Str) #

sub list-all(Str:D $prefix, Bool:D $colour, Int:D $page-length, Regex:D $pattern --> Bool:D) is export {
    my Str @result;
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    for %the-lot.kv -> $key, %val {
        if $key.starts-with($prefix, :ignorecase) && $key ~~ $pattern {
            my Str $host       = %val«host»;
            my Str $type       = %val«type»;
            my Int $port;
            if $type eq 'host' {
                $port          = %val«port»;
            }else {
                $port          = 0;
            }
            my Str $comment    = %val«comment» // Str;
            without $host {
                next;
            }
            if $host.trim eq '' {
                next;
            }
            without $port {
                $port = 22;
            }
            $key-width         = max($key-width,     wcswidth($key));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth((($port == 0) ?? '--' !! $port)));
            with $comment {
                $comment-width = max($comment-width, wcswidth($comment));
            }
        }
    } # for %the-lot.kv -> $key, %val #
    $key-width     += 2;
    $host-width    += 2;
    $port-width    += 2;
    $comment-width += 2;
    my Bool:D $comment-present = False;
    for %the-lot.kv -> $key, %val {
        if $key.starts-with($prefix, :ignorecase) && $key ~~ $pattern {
            my Str:D $host      = %val«host»;
            my Str:D $type      = %val«type»;
            my Int:D $port = 0;
            if $type eq 'host' {
                $port          = %val«port»;
            }
            my Str   $comment   = %val«comment» // Str;
            without $host {
                next;
            }
            if $host.trim eq '' {
                next;
            }
            without $port {
                $port = 22;
            }
            with $comment {
                @result.push(sprintf("%-*s %s %-*s : %-*s # %-*s", $key-width, $key, (($port == 0) ?? '-->' !! " =>"), $host-width, $host, $port-width, (($port == 0) ?? '--' !! "$port"), $comment-width, $comment));
                $comment-present = True;
            } else {
                @result.push(sprintf("%-*s %s %-*s : %-*s", $key-width, $key, (($port == 0) ?? '-->' !! " =>"), $host-width, $host, $port-width, (($port == 0) ?? '--' !! "$port")));
            }
        }
    } # for %the-lot.kv -> $key, %val #
    my Int:D $width = $key-width + $host-width + $port-width + $comment-width + 11;
    my Int:D $cnt = 0;
    if $colour {
        if $comment-present {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s # %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
            $cnt++;
        } else {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
            $cnt++;
        }
    } else {
        if $comment-present {
            printf("%-*s sep %-*s : %-*s # %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment');
            $cnt++;
            say '=' x $width;
            $cnt++;
        } else {
            printf("%-*s  => %-*s : %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port');
            $cnt++;
            say '=' x $width;
            $cnt++;
        }
    }
    for @result.sort( { .lc } ) -> $value {
        if $colour {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, $value) ~ t.text-reset;
            $cnt++;
            if $cnt % $page-length == 0 {
                if $comment-present {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s  sep %-*s : %-*s # %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                } else {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s  sep %-*s : %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                }
            } # if $cnt % $page-length == 0 #
        } else { # if $colour #
            $value.say;
            $cnt++;
            if $cnt % $page-length == 0 {
                if $comment-present {
                    say '=' x $width;
                    $cnt++;
                    printf("%-*s  sep %-*s : %-*s # %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment');
                    $cnt++;
                    say '=' x $width;
                    $cnt++;
                } else {
                    say '=' x $width;
                    $cnt++;
                    printf("%-*s  sep %-*s : %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port');
                    $cnt++;
                    say '=' x $width;
                    $cnt++;
                }
            } # if $cnt % $page-length == 0 #
        } # if $colour ... else ... #
    } # for @result.sort( { .lc } ) -> $value #
    if $colour {
        put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, '') ~ t.text-reset;
        $cnt++;
    } else {
        "".say;
    }
    return True;
} # sub list-all(Str:D $prefix, Bool:D $colour, Int:D $page-length, Regex:D $pattern --> Bool:D) is export #

sub list-hosts(Str:D $prefix, Bool:D $colour, Int:D $page-length, Regex:D $pattern --> Bool:D) is export {
    my Str @result;
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    for %the-lot.kv -> $key, %val {
        my Str $host      = %val«host»;
        my Str $type      = %val«type»;
        my Int:D $port = 0;
        if $type eq 'host' {
            $port          = %val«port»;
        }
        without $host {
            next;
        }
        if $host.trim eq '' {
            next;
        }
        without $port {
            $port = 22;
        }
        if $host.starts-with("$prefix", :ignorecase) && $host ~~ $pattern {
            my Str $comment    = %val«comment» // Str;
            $key-width         = max($key-width,     wcswidth($key));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $comment {
                $comment-width = max($comment-width, wcswidth($comment));
            }
        }
    } # for %the-lot.kv -> $key, %val #
    $key-width     += 2;
    $host-width    += 2;
    $port-width    += 2;
    $comment-width += 2;
    my Bool:D $comment-present = False;
    for %the-lot.kv -> $key, %val {
        my Str:D $host     = %val«host»;
        my Str:D $type     = %val«type»;
        my Int:D $port = 0;
        if $type eq 'host' {
            $port          = %val«port»;
        }
        without $host {
            next;
        }
        if $host.trim eq '' {
            next;
        }
        without $port {
            $port = 22;
        }
        if $host.starts-with("$prefix", :ignorecase) && $host ~~ $pattern {
            my Str   $comment   = %val«comment» // Str;
            with $comment {
                @result.push(sprintf("%-*s %s %-*s : %-*s # %-*s", $key-width, $key, (($port == 0) ?? '-->' !! " =>"), $host-width, $host, $port-width, (($port == 0) ?? '--' !! "$port"), $comment-width, $comment));
                $comment-present = True;
            } else {
                @result.push(sprintf("%-*s %s %-*s : %-*s", $key-width, $key, (($port == 0) ?? '-->' !! " =>"), $host-width, $host, $port-width, (($port == 0) ?? '--' !! "$port")));
            }
        }
    } # for %the-lot.kv -> $key, %val #
    my Int:D $width = $key-width + $host-width + $port-width + $comment-width + 11;
    my Int:D $cnt = 0;
    if $colour {
        if $comment-present {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s # %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
            $cnt++;
        } else {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
            $cnt++;
        }
    } else {
        if $comment-present {
            printf("%-*s sep %-*s : %-*s # %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment');
            $cnt++;
            say '=' x $width;
            $cnt++;
        } else {
            printf("%-*s sep %-*s : %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port');
            $cnt++;
            say '=' x $width;
            $cnt++;
        }
    }
    for @result.sort( { .lc } ) -> $value {
        if $colour {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, $value) ~ t.text-reset;
            $cnt++;
            if $cnt % $page-length == 0 {
                if $comment-present {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s # %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                } else {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                }
            } # if $cnt % $page-length == 0 #
        } else { # if $colour #
            $value.say;
            $cnt++;
            if $cnt % $page-length == 0 {
                if $comment-present {
                    say '=' x $width;
                    $cnt++;
                    printf("%-*s sep %-*s : %-*s # %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment');
                    $cnt++;
                    say '=' x $width;
                    $cnt++;
                } else {
                    say '=' x $width;
                    $cnt++;
                    printf("%-*s sep %-*s : %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port');
                    $cnt++;
                    say '=' x $width;
                    $cnt++;
                }
            } # if $cnt % $page-length == 0 #
        } # if $colour ... else ... #
    } # for @result.sort( { .lc } ) -> $value #
    if $colour {
        put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, '') ~ t.text-reset;
        $cnt++;
    } else {
        "".say;
    }
    return True;
} # sub list-hosts(Str:D $prefix, Bool:D $colour, Int:D $page-length, Regex:D $pattern --> Bool:D) is export #

sub list-by-both(Str:D $prefix, Bool:D $colour, Int:D $page-length, Regex:D $pattern --> Bool:D) is export {
    my Str @result;
    my Int:D $key-width        = 0;
    my Int:D $host-width       = 0;
    my Int:D $port-width       = 0;
    my Int:D $comment-width    = 0;
    for %the-lot.kv -> $key, %val {
        my Str $host      = %val«host»;
        my Str $type      = %val«type»;
        my Int $port = 0;
        if $type eq 'host' {
            $port         = %val«port»;
        }
        without $host {
            next;
        }
        if $host.trim eq '' {
            next;
        }
        without $port {
            $port = 22;
        }
        if ($key.starts-with($prefix, :ignorecase) && $key ~~ $pattern) || ($host.starts-with("$prefix", :ignorecase) && $host ~~ $pattern) {
            my Str $comment    = %val«comment» // Str;
            $key-width         = max($key-width,     wcswidth($key));
            $host-width        = max($host-width,    wcswidth($host));
            $port-width        = max($port-width,    wcswidth($port));
            with $comment {
                $comment-width = max($comment-width, wcswidth($comment));
            }
        }
    } # for %the-lot.kv -> $key, %val #
    $key-width     += 2;
    $host-width    += 2;
    $port-width    += 2;
    $comment-width += 2;
    my Bool:D $comment-present = False;
    for %the-lot.kv -> $key, %val {
        my Str:D $host     = %val«host»;
        my Str:D $type     = %val«type»;
        my Int:D $port     = 0;
        if $type eq 'host' {
            $port          = %val«port»;
        }
        without $host {
            next;
        }
        if $host.trim eq '' {
            next;
        }
        without $port {
            $port = 22;
        }
        if ($key.starts-with($prefix, :ignorecase) && $key ~~ $pattern) || ($host.starts-with("$prefix", :ignorecase) && $host ~~ $pattern) {
            my Str   $comment   = %val«comment» // Str;
            with $comment {
                @result.push(sprintf("%-*s %s %-*s : %-*s # %-*s", $key-width, $key, (($port == 0) ?? '-->' !! " =>"), $host-width, $host, $port-width, (($port == 0) ?? '--' !! "$port"), $comment-width, $comment));
                $comment-present = True;
            } else {
                @result.push(sprintf("%-*s %s %-*s : %-*s", $key-width, $key, (($port == 0) ?? '-->' !! " =>"), $host-width, $host, $port-width, (($port == 0) ?? '--' !! "$port")));
            }
        }
    } # for %the-lot.kv -> $key, %val #
    my Int:D $width = $key-width + $host-width + $port-width + $comment-width + 11;
    my Int:D $cnt = 0;
    if $colour {
        if $comment-present {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s # %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
            $cnt++;
        } else {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port') ~ t.text-reset;
            $cnt++;
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
            $cnt++;
        }
    } else {
        if $comment-present {
            printf("%-*s sep %-*s : %-*s # %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment');
            $cnt++;
            say '=' x $width;
            $cnt++;
        } else {
            printf("%-*s sep %-*s : %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port');
            $cnt++;
            say '=' x $width;
            $cnt++;
        }
    }
    for @result.sort( { .lc } ) -> $value {
        if $colour {
            put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, $value) ~ t.text-reset;
            $cnt++;
            if $cnt % $page-length == 0 {
                if $comment-present {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s # %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                } else {
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s sep %-*s : %-*s", $key-width, 'key', $host-width, 'host', $port-width, 'port') ~ t.text-reset;
                    $cnt++;
                    put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, centre('', $width, '=')) ~ t.text-reset;
                    $cnt++;
                }
            } # if $cnt % $page-length == 0 #
        } else { # if $colour #
            $value.say;
            $cnt++;
            if $cnt % $page-length == 0 {
                if $comment-present {
                    say '=' x $width;
                    $cnt++;
                    printf("%-*s sep %-*s : %-*s # %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port', $comment-width, 'comment');
                    $cnt++;
                    say '=' x $width;
                    $cnt++;
                } else {
                    say '=' x $width;
                    $cnt++;
                    printf("%-*s sep %-*s : %-*s\n", $key-width, 'key', $host-width, 'host', $port-width, 'port');
                    $cnt++;
                    say '=' x $width;
                    $cnt++;
                }
            } # if $cnt % $page-length == 0 #
        } # if $colour ... else ... #
    } # for @result.sort( { .lc } ) -> $value #
    if $colour {
        put (($cnt % 2 == 0) ?? t.bg-yellow !! t.bg-color(0,255,0)) ~ t.bold ~ t.bright-blue ~ sprintf("%-*s", $width, '') ~ t.text-reset;
        $cnt++;
    } else {
        "".say;
    }
    return True;
} # sub list-by-both(Str:D $prefix, Bool:D $colour, Int:D $page-length, Regex:D $pattern --> Bool:D) is export #

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

sub delete-key(Str:D $key, Bool:D $comment-out --> Bool) is export {
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
    while $ln = $input.get {
        if $ln ~~ rx/^ $key \h* [ '-->' || '=>' ] \h* [ <-[ # : ]>+ ] \h* ':' \h* \d+ \h* '#' \h* .* $/ {
            if $comment-out {
                $output.say: "# $ln";
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
} # sub delete-key(Str:D $key, Bool:D $comment-out --> Bool) is export #

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
    while $ln = $input.get {
        $*OUT.flush;
        my $actions = LineActions;
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
    }
    $input.close;
    $output.close;
    if "$config/hosts.h_ts.new".IO.move: "$config/hosts.h_ts" {
        return True;
    } else {
        return False;
    }
}

sub add-alias(Str:D $key, Str:D $target, Bool:D $force is copy, Bool:D $overwrite-hosts, Str $comment is copy --> Bool) is export {
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
                my Str $ln;
                while $ln = $input.get {
                    if $ln ~~ rx/^ \s* $key \s* $<type> = [ '-->' | '=>' ] \s* .* $/ {
                        if ~$<type> eq 'alias' || $overwrite-hosts {
                            $output.say: $line;
                        } else {
                            $output.say: $ln
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
        if $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
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
        if $ln ~~ rx/^ \s* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* ':' \h* $<port> = [ \d+ ] \h* [ '#' \h* $<comment> = [ .* ] ]?  $/ {
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
        if $ln ~~ rx/^ \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
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
        $ln = $input.get;
    } # while !$input.eof #
    if $ln {
        if $ln ~~ rx/^ \h* $<key> = [ \w* [ <-[\h]>+ \w* ]* ] \h* $<type> = [ '-->' || ' =>' ] \h* $<host> = [ <-[ : # ]>+ ] \h* [ ':' \h* $<port> = [ \d+ ] \h* ]? [ '#' \h* $<comment> = [ .* ] ]?  $/ {
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
        while !$input.eof {
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
                $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf("%3s", $type-spec);
                if $port > 0 {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf(" %-*s", 3, " : ") ~ t.text-reset;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf("%-*d", $port-width - 3, $port) ~ t.text-reset;
                }else {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,255,0) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf(" %-*s", $port-width, " : ") ~ t.text-reset;
                }
                with %v«comment» {
                    my Str $comment = %v«comment»;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,0,255) ~ sprintf(" # %-*s", $comment-width, $comment) ~ t.text-reset;
                }
                put $cline ~ t.text-reset;
            }
            $ln = $input.get;
            $cnt++;
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
                $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf("%3s", $type-spec);
                if $port > 0 {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf(" %-*s", 3, " : ") ~ t.text-reset;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(255,0,255) ~ sprintf("%-*d", $port-width - 3, $port) ~ t.text-reset;
                }else {
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,255,0) ~ sprintf(" %-*s", $host-width, $host);
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.red ~ sprintf(" %-*s", $port-width, " : ") ~ t.text-reset;
                }
                with %v«comment» {
                    my Str $comment = %v«comment»;
                    $cline ~= ($cond ?? t.bg-color(63,63,63) !! t.bg-color(127,127,127)) ~ t.bold ~ t.color(0,0,255) ~ sprintf(" # %-*s", $comment-width, $comment) ~ t.text-reset;
                }
                put $cline ~ t.text-reset;
            }
        } # $ln #
    } else {
        $ln = $input.get;
        while !$input.eof {
            say $ln;
            $ln = $input.get;
        } # while !$input.eof #
        if $ln {
            say $ln;
        } # $ln #
    }
    $input.close;
} # sub show-file( --> Bool) is export #

sub say-coloured(Str:D $USAGE --> True) is export {
    my @usage = $USAGE.split("\n");
    my $actions = UsageStrActions;
    #my $test = UsageStr.parse(@usage.join("\x0A"), :enc('UTF-8'), :$actions).made;
    #dd $test, $?NL;
    my @usage-struct = |(UsageStr.parse(@usage.join("\x0A"), :enc('UTF-8'), :$actions).made);
    my Int:D $width = 0;
    for @usage-struct -> %line {
        my Str $kind = %line«kind»;
        if $kind eq 'usage' {
            my Str $value = %line«value»;
            $width = max($width,    wcswidth($value));
        } elsif $kind eq 'usage-line' {
            my %value            = %line«value»;
            my Str $prog         = %value«prog»;
            my @fixed-args       = %value«fixed-args»;
            my @positional-args  = %value«positional-args»;
            my @optionals        = %value«optionals»;
            my Str $slurpy-array = %value«slurpy-array»;
            my @options          = %value«options»;
            my Str $slurpy-hash  = %value«slurpy-hash»;
            my Str:D $ln = ' ' x 2;
            $ln ~= $prog ~ ' ';
            for @fixed-args -> $arg {
                $ln ~= $arg ~ ' ';
            }
            for @positional-args -> $arg {
                $ln ~= $arg ~ ' ';
            }
            for @optionals -> $arg {
                $ln ~= $arg ~ ' ';
            }
            $ln ~= $slurpy-array ~ ' ';
            for @options -> $arg {
                $ln ~= $arg ~ ' ';
            }
            $ln ~= $slurpy-hash ~ ' ';
            $width = max($width,    wcswidth($ln));
        } else {
        }
    } # for @usage -> $line #
    my Int $terminal-width = terminal-width;
    $terminal-width = 80 if $terminal-width === Int;
    $width = min($width, $terminal-width);
    for @usage-struct -> %line {
        my Str $kind = %line«kind»;
        if $kind eq 'usage' {
            my Str $value = %line«value»;
            my Str $ref = $value;
            put t.bg-blue ~ t.bold ~ t.red ~ sprintf("%-*s", $width, left($value, $width, :$ref)) ~ t.text-reset;
        } elsif $kind eq 'usage-line' {
            my %value            = %line«value»;
            my Str $prog         = %value«prog»;
            my @fixed-args       = %value«fixed-args»;
            my @positional-args  = %value«positional-args»;
            my @optionals        = %value«optionals»;
            my Str $slurpy-array = %value«slurpy-array»;
            my @options          = %value«options»;
            my Str $slurpy-hash  = %value«slurpy-hash»;
            my Str:D $ln = ' ' x 2;
            $ln ~= t.color(0,255,0) ~ $prog ~ ' ' ~ t.color(255,0,255);
            my Str $ref = ' ' x 2 ~ $prog ~ ' ';
            for @fixed-args -> $arg {
                $ln ~= $arg ~ ' ';
                $ref ~= $arg ~ ' ';
            }
            $ln ~= t.color(255, 0, 0);
            for @positional-args -> $arg {
                $ln ~= $arg ~ ' ';
                $ref ~= $arg ~ ' ';
            }
            $ln ~= t.color(0, 255, 255);
            for @optionals -> $arg {
                $ln ~= $arg ~ ' ';
                $ref ~= $arg ~ ' ';
            }
            $ln ~= t.color(255, 255, 0) ~ $slurpy-array ~ t.red ~ ' ';
            $ref ~= $slurpy-array ~ ' ';
            for @options -> $arg {
                $ln ~= $arg ~ ' ';
                $ref ~= $arg ~ ' ';
            }
            $ln ~= t.color(255, 128, 128) ~ $slurpy-hash ~ ' ';
            $ref ~= $slurpy-hash ~ ' ';
            put t.bg-blue ~ t.bold ~ sprintf("%-*s", $width, left($ln, $width, :$ref)) ~ t.text-reset;
        } else {
        }
    } # for @usage -> $line #
} # sub say-coloured(Str:D $USAGE --> True) is export #

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

multi sub _get('home', Str:D $key, Bool :r(:$recursive) = False, *@args --> Bool) is export {
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
                my Proc $r = run 'scp', '-r', '-P', $port, "$host:$arg", '.';
                $result +&= $r.exitcode;
            } else {
                ('scp', '-P', $port, "$host:$arg", '.').join(' ').say;
                my Proc $r = run 'scp', '-P', $port, "$host:$arg", '.';
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

multi sub _put('home', Str:D $key, Bool :r(:$recursive) = False, *@args --> Bool) is export {
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
            ('scp', '-r', '-P', $port, |@args, "$host:").join(' ').say;
            my Proc $r = run 'scp', '-r', '-P', $port, |@args, "$host:";
            if $r.exitcode == 0 {
                return True;
            }
            die "non-zero exit code";
        } else {
            ('scp', '-P', $port, |@args, "$host:").join(' ').say;
            my Proc $r = run 'scp', '-P', $port, |@args, "$host:";
            if $r.exitcode == 0 {
                return True;
            }
            die "non-zero exit code";
        }
    }
    die "key $key not found";
} # multi sub put('home', Str:D $key, Bool $recursive, *@args --> Bool) is export #
