use Test;

use Rubyish::Grammar;
use Rubyish::Actions;

 subtest "eval sanity", {
     for "4" => 4, "4+-3" => 1, "4+2+36" => 42, "0b111" => 7, "0xA" => 10,
     "-42" => -42, "2++40" => 42, "(2+3)" => 5, "2+3*5" => 17, "(2+3)*5" => 25,
     "8/2" => 4.0, "((4*3)-(3*2))" => 6, "1_234" => 1234, "4.2" => 4.2, "4.2+1" => 5.2
     {
         my $expr = .key;
         my $expected-result = .value;
         my Rubyish::Actions $actions .= new;
         subtest $expr, {
             ok Rubyish::Grammar.parse($expr, :$actions), "parse";
             is-deeply $/.ast.EVAL, $expected-result, "calculation";
         }
    }
}

done-testing();
