unit class Rubyish::Actions;

use experimental :rakuast;

use HLL::Expression::Grammar::Actions;
also does HLL::Expression::Grammar::Actions;

method TOP($/) { make $<stmt>.ast }

method !compile-expr($/) {
    my $expr-ast := $<EXPR>.ast.head;
    $expr-ast.&compile-expr;
}

method stmt:sym<EXPR>($/) {
    make self!compile-expr($/); 
}

method term:sym<value>($/) {
    make $<value>.ast;
}

method value:sym<uint>($/) { make $<uint>.ast }
method uint($/) { make RakuAST::IntLiteral.new($/.Int) }
method value:sym<nil>($) {
    make RakuAST::Type::Simple.new(
        RakuAST::Name.from-identifier("Nil")
    )
}
method value:sym<true>($) {
    make RakuAST::Term::Enum.from-identifier('True');
}
method value:sym<false>($) {
    make RakuAST::Term::Enum.from-identifier('False');
}

method circumfix:sym<( )>($/) {  make self!compile-expr($/); }
method term:sym<circumfix>($/) { make $<circumfix>.ast }

multi sub compile-expr(% (:infix($op)!, :left($lhs)!, :right($rhs)!)) {
    my $left = $lhs.&compile-expr;
    my $right = $rhs.&compile-expr;
    my RakuAST::Infix $infix .= new($op);
    RakuAST::ApplyInfix.new(
        :$left, :$infix, :$right
    )
}

multi sub compile-expr(% (:prefix($op)!, :operand($node)!)) {
    my $operand = $node.&compile-expr;
    my RakuAST::Prefix $prefix .= new($op);
    RakuAST::ApplyPrefix.new(
        :$prefix, :$operand
    )
}

multi sub compile-expr(% (:postfix($op)!, :operand($node)!)) {
    my $operand = $node.&compile-expr;
    my RakuAST::Postfix $postfix .= new($op);
    RakuAST::ApplyPostfix.new(
        :$postfix, :$operand,
    )
}

multi sub compile-expr($leaf-node) { $leaf-node } 
