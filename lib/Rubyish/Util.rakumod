unit module Rubyish::Util;

use experimental :rakuast;

proto sub compile-expr(|) is export(:compile-expr) {*}

multi sub infix('=', $name, $initializer) {
    RakuAST::VarDeclaration::Term.new(
        :$name, :$initializer,
    );
}

multi sub infix($op, $lhs, $rhs) {
    my $left = $lhs.&compile-expr;
    my $right = $rhs.&compile-expr;
    my RakuAST::Infix $infix .= new($op);
    RakuAST::ApplyInfix.new(
        :$left, :$infix, :$right
    )
}

multi sub compile-expr(% (:infix($op)!, :$left!, :$right!)) {
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
