use Test;

use experimental :rakuast;

use Rubyish::Grammar;
use Rubyish::Actions;

 subtest "eval sanity", {
     for "4" => 4, "4+-3" => 1, "4+2+36" => 42, "0b111" => 7, "0xA" => 10,
     "-42" => -42, "2++40" => 42, "(2+3)" => 5, "2+3*5" => 17, "(2+3)*5" => 25,
     "8/2" => 4.0, "((4*3)-(3*2))" => 6, "1_234" => 1234, "4.2" => 4.2,
     "4.2+1" => 5.2, "1.23e-7" => 1.23e-7, "3 > 2" => True, "2 > 3" => False,
     "true" => True, "false" => False, "nil" => Nil {
         my $expr = .key;
         my $expected-result := .value;
         my Rubyish::Actions $actions .= new;
         subtest $expr, {
             ok Rubyish::Grammar.parse($expr, :$actions), "parse";
             my RakuAST::Statement::Expression $stmt = $/.ast;
             is-deeply $stmt.EVAL, $expected-result, "calculation";
         }
    }
}

done-testing();
