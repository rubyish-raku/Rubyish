unit class Rubyish;

use Rubyish::Grammar;
use Rubyish::Actions;

method grammar {Rubyish::Grammar}
method actions {Rubyish::Actions.new}

multi method compile(Str:D $code, Str:D :$rule = 'TOP') {
    .ast given $.grammar.parse($code, :$.actions, :$rule);
}

method eval(Str:D $code, *%o) {
    $.compile($code, |%o).EVAL;
}
