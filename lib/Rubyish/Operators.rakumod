unit module Rubyish::Operators;

role Grammar {
    ## Operator precedence levels
    #  -- see https://www.tutorialspoint.com/ruby/ruby_operators.htm

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
    my %ternary        = :$slack, :assoc<right>;  # ?:

    $slack++;
    my %logical-or     = :$slack, :assoc<left>;  # ||

    $slack++;
    my %assignment     = :$slack, :assoc<right>; # = %= { /= -= += |= &= >>= <<= *= &&= ||= **=

    $slack++;
    my %loose-not      = :$slack, :assoc<unary>; # not (unary)

    $slack++;
    my %loose-logical  =  :$slack, :assoc<left>; # or and

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

    token infix:sym<?:>   {:s '?' <EXPR> ':' <O(|%ternary, :op<?:>)> }

    token assign-op       {'='<![>=]>}
    token infix:sym<=>    { <.assign-op> <O(|%assignment)> }

    token prefix:sym<not> { <sym>  <O(|%loose-not)> }
    token infix:sym<and>  { <sym>  <O(|%loose-logical)> }
    token infix:sym<or>   { <sym>  <O(|%loose-logical)> }

    # Parenthesis
    token circumfix:sym<( )> { :my $*IN-PARENS := True;
                               '(' ~ ')' <EXPR> <O(|%methodop)> }

    # Method call
    token postfix:sym<.>  {
        '.' <operation> [ '(' ~ ')' <call-args=.paren-args>? ]?
        <O(|%methodop)>
    }

    # Array and hash indices
    token postcircumfix:sym<[ ]> { '[' ~ ']' [ <EXPR> ] <O(|%methodop, :op<[]>)> }
    token postcircumfix:sym<{ }> { '{' ~ '}' [ <EXPR> ] <O(|%methodop, :op<{}>)> }
}

role Actions {
    use experimental :rakuast;
    use Rubyish::Util :&compile;
    
    method circumfix:sym<( )>($/) {  make $<EXPR>.&compile; }
    method postcircumfix:sym<[ ]>($/) {
        my $expression = $<EXPR>.&compile;
        my RakuAST::SemiList $index .= new(
            RakuAST::Statement::Expression.new(
                :$expression
            )
        );
        make RakuAST::Postcircumfix::ArrayIndex.new(:$index);
    }
}
