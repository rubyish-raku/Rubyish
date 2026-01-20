unit module Rubyish::Util;

use experimental :rakuast;

multi sub infix('=', $name, $initial-value) {
    my $id = $name.DEPARSE;
    nextsame if %*SYM{$id}:exists;

    my $block = $*CUR-BLOCK;
    my $sym = $block.symbol($id);
    %*SYM{$id} = 'var';
    $sym.declared = True;
    my RakuAST::Initializer::Assign $initializer .= new($initial-value);
    $initializer .= new(RakuAST::VarDeclaration::Anonymous.new(:sigil<$>, :$initializer));
 
    RakuAST::VarDeclaration::Term.new(
        :$name, :$initializer,
    );
}

multi sub infix($op, $left, $right) is export(:infix) {
    my RakuAST::Infix $infix .= new($op);
    RakuAST::ApplyInfix.new(
        :$left, :$infix, :$right
    )
}

multi sub compile-expr(% (:infix($op)!, :$left! is copy, :$right! is copy)) {
    $left  .= &compile-expr;
    $right .= &compile-expr;
    $op.&infix: $left, $right;
}

multi sub compile-expr(% (:ternary($)!, :$left!, :$mid!, :$right!)) {
    my $condition = $left.&compile-expr;
    my $then = $mid.&compile-expr;
    my $else = $right.&compile-expr;
    RakuAST::Ternary.new(
        :$condition, :$then, :$else
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

sub compile($/) is export(:compile) {
    $/.ast.head.&compile-expr;
}

