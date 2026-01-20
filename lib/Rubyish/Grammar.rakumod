unit grammar Rubyish::Grammar;

use HLL::Expression::Grammar;
also does HLL::Expression::Grammar;

use       Rubyish::Operators;
also does Rubyish::Operators::Grammar;

use       Rubyish::Values;
also does Rubyish::Values::Grammar;

use Rubyish::HLL::Block;

token TOP {
    :my $*IN_TEMPLATE = False;           # true, if in a template
    :my $*IN_PARENS   = False;           # true, if in a parenthesised list
    :my $*CUR-BLOCK = Rubyish::HLL::Block.new;
    :my %*SYM;                           # symbols in current scope
    ^ ~ $ <stmtlist>
        || <.panic('Syntax error')>
}

# Comments and whitespace
proto token comment {*}
token comment:sym<line>   { '#' [<?{!$*IN_TEMPLATE}> \N* || [<!before <tmpl-unesc>>\N]*] }
token comment:sym<podish> {[^^'=begin'\n] [ .*? [^^'=end'[\n|$]] || <.panic('missing ^^=end at eof')>] }

token ws { <!ww> [\h | <.continuation> | <.comment> | <?{$*IN_PARENS}> \n ]* }
token hs { <!ww> [\h | <.continuation> ]* }

rule separator       { ';' | \n <!after continuation> }
token continuation   { \\ \n }

rule stmtlist {
    [ <stmt=.stmtish>? ] *%% <.separator>
}

#| a single statement, plus optional modifier
token stmtish {:s
    <stmt> [ <modifier> <EXPR>]?
}
token modifier {if|unless|while|until}

sub is-variable($op) {
    my $type := %*SYM{$op} // %*SYM-GBL{$op};

    $type ~~ 'var';
}
token var {
    $<var>=[<!keyword> <ident> <!before [ \! | \? | <hs>\( ]>]
    [  <?before <hs> <.assign-op> >
       || <?{ is-variable(~$<var>) }>
       ||  <.panic("unknown variable or method: $<var>")>
    ]
}

token term:sym<var> { <var> }
token term:sym<value> { <value> }
token term:sym<circumfix> {:s <circumfix> }

proto token stmt { <...> }

token stmt:sym<EXPR> { <EXPR> }

# Reserved words.
token keyword {
    [ BEGIN     | class     | ensure    | nil       | new       | when
    | END       | def       | false     | not       | super     | while
    | alias     | defined   | for       | or        | then      | yield
    | and       | do        | if        | redo      | true
    | begin     | else      | in        | rescue    | undef
    | break     | elsif     | module    | retry     | unless
    | case      | end       | next      | return    | until
    | eq | ne   | lt | gt   | le | ge   | cmp
    ] <!ww>
}

method panic($err) { die $err }
