unit grammar Rubyish::Grammar;

use HLL::Expression::Grammar;
also does HLL::Expression::Grammar;

##use Rubyish::HLL::Block;

token term:sym<value> { <value> }
token term:sym<circumfix> {:s <circumfix> }

proto token value { * }
token value:sym<uint> { <uint> }
token uint { \d+ }
token value:sym<nil>     { <sym> }
token value:sym<true>    { <sym> }
token value:sym<false>   { <sym> }

token TOP {
    ##    ^ ~ $ <stmtlist> ## todo
    
    <stmt> || <.panic('Syntax error')>
}

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

## Operator precedence levels
#  -- see https://www.tutorialspoint.com/ruby/ruby_operators.htmw

my $slack = 0;
my %methodop       = :$slack, :assoc<unary>; # method call

my %exponentiation = :$slack, :assoc<left>;  # **

$slack++;
my %unary          = :$slack, :assoc<unary>; # ! ~ + - (unary)

$slack++;
my %multiplicative = :$slack, :assoc<left>;  # * / %

$slack++;
my %additive       = :$slack, :assoc<left>;  # + -

$slack++;
my %bitshift       = :$slack, :assoc<left>;  # >> <<

$slack++;
my %bitand         = :$slack, :assoc<left>;  # &

$slack++;
my %bitor          = :$slack, :assoc<left>;  # ^ |

$slack++;
my %comparison     = :$slack, :assoc<left>;  # <= < > >= le lt gt ge

$slack++;
my %equality       = :$slack, :assoc<left>;  # <> == === != =~ !~ eq ne cmp

$slack++;
my %logical-and    = :$slack, :assoc<left>;  # &&

$slack++;
my %ternary        = :$slack, :assoc<left>;     # ?:

$slack++;
my %logical-or     = :$slack, :assoc<left>;  # ||

$slack++;
my %assignment     = :$slack, :assoc<right>; # = %= { /= -= += |= &= >>= <<= *= &&= ||= **=

$slack++;
my %loose_not      = :$slack, :assoc<unary>; # not (unary)

$slack++;
my %loose_logical  =  :$slack, :assoc<left>; # or and

token infix:sym<**>   { <sym>       <O(|%unary)> }

token prefix:sym<->   { <sym><![>]> <O(|%unary)> }
token prefix:sym<+>   { <sym>       <O(|%unary)> }
token prefix:sym<!>   { <sym>       <O(|%unary)> }

token infix:sym<*>    { <sym>       <O(|%multiplicative)> }
token infix:sym</>    { <sym>       <O(|%multiplicative)> }
token infix:sym<%>    { <sym><![>]> <O(|%multiplicative)> }

token infix:sym<+>    { <sym>       <O(|%additive)> }
token infix:sym<->    { <sym>       <O(|%additive)> }
token infix:sym<~>    { <sym>       <O(|%additive)> }

token infix:sym«<<»   { <sym>       <O(|%bitshift)> }
token infix:sym«>>»   { <sym>       <O(|%bitshift)> }

token infix:sym<&>    { <sym>       <O(|%bitand)> }
token infix:sym<|>    { <sym>       <O(|%bitor)> }
token infix:sym<^>    { <sym>       <O(|%bitor)> }

token infix:sym«<=»   { <sym><![>]> <O(|%comparison)> }
token infix:sym«>=»   { <sym>       <O(|%comparison)> }
token infix:sym«<»    { <sym>       <O(|%comparison)> }
token infix:sym«>»    { <sym>       <O(|%comparison)> }
token infix:sym«le»   { <sym>       <O(|%comparison)> }
token infix:sym«ge»   { <sym>       <O(|%comparison)> }
token infix:sym«lt»   { <sym>       <O(|%comparison)> }
token infix:sym«gt»   { <sym>       <O(|%comparison)> }

token infix:sym«==»   { <sym>       <O(|%equality)> }
token infix:sym«!=»   { <sym>       <O(|%equality)> }
token infix:sym«<=>»  { <sym>       <O(|%equality)> }
token infix:sym«eq»   { <sym>       <O(|%equality)> }
token infix:sym«ne»   { <sym>       <O(|%equality)> }
token infix:sym«cmp»  { <sym>       <O(|%equality)> }

token infix:sym<&&>   { <sym>       <O(|%logical-and)> }
token infix:sym<||>   { <sym>       <O(|%logical-or)> }

token infix:sym<? :>  {:s '?' <O(|%ternary)> <EXPR>
                          ':' <O(|%ternary, :reducecheck<ternary>)>
}

token assign-op       {'='<![>=]>}
token infix:sym<=>    { <.assign-op> <O(|%assignment)> }

token prefix:sym<not> { <sym>  <O(|%loose_not)> }
token infix:sym<and>  { <sym>  <O(|%loose_logical)> }
token infix:sym<or>   { <sym>  <O(|%loose_logical)> }

# Parenthesis
token circumfix:sym<( )> { :my $*IN-PARENS := True;
                           '(' ~ ')' <EXPR> <O(|%methodop)> }

# Method call
token postfix:sym<.>  {
    '.' <operation> [ '(' ~ ')' <call-args=.paren-args>? ]?
    <O(|%methodop)>
}

# Array and hash indices
token postcircumfix:sym<[ ]> { '[' ~ ']' [ <EXPR> ] <O(|%methodop)> }
token postcircumfix:sym<{ }> { '{' ~ '}' [ <EXPR> ] <O(|%methodop)> }
token postcircumfix:sym<ang> {
    <?[<]> <quote_EXPR: ':q'>
    <O(|%methodop)>
}

method panic($err) { die $err }
