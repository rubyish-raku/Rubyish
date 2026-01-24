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
    # wrap it in an anonymous declaration to get a rw container
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

# ternary
multi sub compile-expr(% (:infix($)!, :$left!, :$expr!, :$right!)) {
    my $condition = $left.&compile-expr;
    my $then = $expr.&compile-expr;
    my $else = $right.&compile-expr;
    RakuAST::Ternary.new(
        :$condition, :$then, :$else
    )
}

multi sub compile-expr(% (:infix($op)!, :$left! is copy, :$right! is copy)) {
    $left  .= &compile-expr;
    $right .= &compile-expr;
    $op.&infix: $left, $right;
}

multi sub postfix('[]', $index) {
    RakuAST::Postcircumfix::ArrayIndex.new: :$index;
}

multi sub postfix('{}', $index) {
    RakuAST::Postcircumfix::HashIndex.new: :$index;
}

multi sub compile-expr(% (:prefix($op)!, :$operand! is copy)) {
    $operand .= &compile-expr;
    my RakuAST::Prefix $prefix .= new($op);
    RakuAST::ApplyPrefix.new(
        :$prefix, :$operand
    )
}

# postcircumfix
multi sub compile-expr(% (:postfix($op)!, :$operand! is copy, :$expr!)) {
    $operand  .= &compile-expr;
    my $expression = $expr.&compile-expr;
    my RakuAST::SemiList $index .= new(
        RakuAST::Statement::Expression.new(:$expression)
    );
    my $postfix = $op.&postfix($index);
    RakuAST::ApplyPostfix.new(
        :$postfix, :$operand,
    )

}

multi sub compile-expr(% (:postfix($op)!, :$operand! is copy)) {
    $operand .= &compile-expr;
    my RakuAST::Postfix $postfix .= new($op);
    RakuAST::ApplyPostfix.new(
        :$postfix, :$operand,
    )
}

multi sub compile-expr($leaf-node) { $leaf-node }

sub compile($/) is export(:compile) {
    $/.ast.head.&compile-expr;
}

