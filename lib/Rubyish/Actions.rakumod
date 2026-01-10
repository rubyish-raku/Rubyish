unit class Rubyish::Actions;

use experimental :rakuast;

use HLL::Expression::Grammar::Actions;
also does HLL::Expression::Grammar::Actions;
use Method::Also;

method TOP($/) { make $<stmt>.ast }

method !compile-expr($/) {
    my $expr-ast := $<EXPR>.ast.head;
    $expr-ast.&compile-expr;
}

method stmt:sym<EXPR>($/) {
    my $expression = self!compile-expr($/);
    make RakuAST::Statement::Expression.new: :$expression;
}

method term:sym<value>($/) {
    make $<value>.ast;
}

multi sub literal(Int:D $v) { RakuAST::IntLiteral.new($v) }
multi sub literal(Rat:D $v) { RakuAST::RatLiteral.new($v) }
multi sub literal(Num:D $v) { RakuAST::NumLiteral.new($v) }

method value:sym<num>($/) { make $<num>.ast }
method unsigned-int($/) { make $/.Int.&literal }
method hex-int($/) { make $/.Int.&literal }
method decimal-num($/) { make $/.Numeric.&literal }
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
