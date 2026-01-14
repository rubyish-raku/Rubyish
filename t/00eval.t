use Test;

use experimental :rakuast;

use Rubyish::Grammar;
use Rubyish::Actions;

sub test-eval(Str:D $expr, Any $expected-result) {
    my Rubyish::Actions $actions .= new;
    subtest $expr, {
        ok Rubyish::Grammar.parse($expr, :$actions), "parse";
        my RakuAST::StatementList $stmts = $/.ast;
        is-deeply $stmts.EVAL, $expected-result, "statement eval";
    }
}

subtest "numeric expressions", {
     for "4" => 4, "4+-3" => 1, "4+2+36" => 42, "0b111" => 7, "0xA" => 10,
     "-42" => -42, "2++40" => 42, "(2+3)" => 5, "2+3*5" => 17, "(2+3)*5" => 25,
     "8/2" => 4.0, "((4*3)-(3*2))" => 6, "1_234" => 1234, "4.2" => 4.2,
     "4.2+1" => 5.2, "1.23e-7" => 1.23e-7, "3 > 2" => True, "2 > 3" => False,
     "true" => True, "false" => False, "nil" => Nil, "1;2" => 2, "2 if true" => 2, "1 if false" => Empty {
         .key.&test-eval: .value;
    }
}

 subtest "quoted strings", {
     for "'foo'" => 'foo', "'foo\\'bar'" => "foo'bar", "'foo\\\\bar'" => "foo\\bar",
     q<"foobar"> => 'foobar', q<"#{42}"> => '42', q<"foo#{40+2}bar"> => 'foo42bar',
     q<"foo#{42 if true}bar"> => 'foo42bar', q<"foo#{42 if false}bar"> => 'foobar',
     ## q<"foo\\\nbar> => "foobar", ## todo
     q<"\\a\\b\\t\\n\\v\\f\\r\\e\\s"> => "\a\b\t\n\x[b]\f\r\e ", q<"\77"> => "?", q<"\cM"> => "\f",
     q<"\\x006E"> => "n", q<"\\u6e"> => "n" {
         .key.&test-eval: .value;
     }
}

done-testing();
