unit class Rubyish::Actions;

use experimental :rakuast;

use HLL::Expression::Grammar::Actions;
also does HLL::Expression::Grammar::Actions;

use       Rubyish::Value;
also does Rubyish::Value::Actions;

use Rubyish::Util :&compile-expr;
use Method::Also;

method TOP($/) {
    make $/.&compile;
}

method stmtlist($/) {
    my RakuAST::Statement::Expression:D @stmts = @<stmt>>>.ast;
    make RakuAST::StatementList.new: |@stmts;
}

method modifier($/) {
    my constant %Modifier = %(
        :if(condition-modifier => RakuAST::StatementModifier::If),
        :unless(condition-modifier => RakuAST::StatementModifier::Unless),
        :while(loop-modifier => RakuAST::StatementModifier::While),
        :until(loop-modifier => RakuAST::StatementModifier::Until),
    );
    make %Modifier{$/};
}

multi method stmtish($/ where $<modifier>) {
    my $expression = $<stmt>.ast;
    my $mod-expr = $/.&compile;
    given $<modifier>.ast {
        make RakuAST::Statement::Expression.new(
            :$expression,
            |(.key => .value.new($mod-expr))
        );
    }
}

multi method stmtish($/) {
    my $expression = $<stmt>.ast;
    make RakuAST::Statement::Expression.new(
        :$expression,
    );
}

method var($/) {
    my $name := ~$<ident>;
    my RakuAST::Name $id .= from-identifier: $name;
    make %*SYM{$name} ?? RakuAST::Term::Name.new($id) !! $id;
}

method stmt:sym<EXPR>($/) {
    make $/.&compile;
}

method term:sym<value>($/) {
    make $<value>.ast;
}

method term:sym<var>($/) {
    my $var =  $<var>.ast;
    make $<var>.ast;
}

method circumfix:sym<( )>($/) {  make $/.&compile; }
method term:sym<circumfix>($/) { make $<circumfix>.ast }

multi sub compile($/ where $<EXPR>) {
    my $expr-ast := $<EXPR>.ast.head;
    $expr-ast.&compile-expr;
}

multi sub compile($/ where $<stmtlist>) {
    $<stmtlist>.ast;
}

method ws($/) is also<ww hs decint escale separator hexdigits xdigit before assign-op> {}

method FALLBACK($method, $/) {
    die "Missing $method actions method"
        unless $method.contains('fix');
}
