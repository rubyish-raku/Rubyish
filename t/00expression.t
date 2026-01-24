use Test;

use experimental :rakuast;

use Rubyish;

sub test-eval(Str:D $code, Any $expected-result) {
    my Rubyish::Actions $actions .= new;
    subtest $code, {
        my RakuAST::StatementList $stmts = Rubyish.compile: $code;
        is-deeply $stmts.EVAL, $expected-result, "statement eval";
    }
}

subtest "numeric expressions", {
    for ("4" => 4, "4+-3" => 1, "4+2+36" => 42, "0b111" => 7, "0xA" => 10,
         "-42" => -42, "2++40" => 42, "(2+3)" => 5, "2+3*5" => 17, "(2+3)*5" => 25,
         "8/2" => 4.0, "((4*3)-(3*2))" => 6, "1_234" => 1234, "4.2" => 4.2,
         "4.2+1" => 5.2, "1.23e-7" => 1.23e-7, "3 > 2" => True, "2 > 3" => False,
         "true" => True, "false" => False, "nil" => Nil, "1;2" => 2, "2 if true" => 2,
         "1 if false" => Empty) {
         .key.&test-eval: .value;
    }
}

subtest "quoted strings", {
    for (q<'foo'> => 'foo', q<'foo\\'bar'> => "foo'bar", q<'foo\\\\bar'> => "foo\\bar",
         q<'fo\\o'> => "fo\\o", q<"fo\\o"> => "fo\\o",
         q<"foobar"> => 'foobar', q<"#{42}"> => '42', q<"foo#{40+2}bar"> => 'foo42bar',
         q<"foo#{42 if true}bar"> => 'foo42bar', q<"foo#{42 if false}bar"> => 'foobar',
         q<"foo\\> ~ "\n" ~ q<bar"> => "foobar", ## todo
         q<"\\a\\b\\t\\n\\v\\f\\r\\e\\s\\"\\\\"> => "\a\b\t\n\x[b]\f\r\e \"\\", q<"\77"> => "?",
         q<"\cM"> => "\f", q<"\\x006E"> => "n", q<"\\u6e"> => "n") {
        .key.&test-eval: .value;
    }
}

subtest "ternary", {
    for ("true ? 1 : 2" => 1, "false ? 1 : 2" => 2, "true ? 1 : true ? 2 : 3" => 1,
         "true ? 1 : false ? 2 : 3" => 1, "false ? 1 : true ? 2 : 3" => 2,
         "(true ? 1 : false ) ? 2 : 3" => 2, "false ? 1 : false ? 2 : 3" => 3,
         "1 + 1 == 2 ? 1+1 : 1-1" => 2,"1 + 1 == 1 ? 1+1 : 1-1" => 0, ) {
        .key.&test-eval: .value;
    }
}

subtest "numeric comparison", {
    my constant f = False;
    my constant t = True;
    for (('==', [f,t,f]), ('!=', [t,f,t]), ('>=', [f,t,t]), ('>', [f,f,t]),
         ('<', [t,f,f]), ('<=', [t,t,f]), ('<=>', [Less,Same,More]))
    -> @ ($op, @expected) {
        for ((1,3), (2,2), (3,1)) -> @ ($a,$b) {
            "$a $op $b".&test-eval: @expected.shift;
        }
    }
}

subtest "string comparison", {
    my constant f = False;
    my constant t = True;
    for (('eq', [f,t,f]), ('ne', [t,f,t]), ('ge', [f,t,t]), ('gt', [f,f,t]),
         ('lt', [t,f,f]), ('le', [t,t,f]), ('cmp', [Less,Same,More]))
    -> @ ($op, @expected) {
        for (('a','c'), ('b','b'), ('c','a')) -> @ ($a,$b) {
            "'$a' $op '$b'".&test-eval: @expected.shift;
        }
    }
}

subtest "variables", {
    for ("x=42" => 42, "x=42;x" => 42, "x=40;x+2" => 42, "x=40;x=42" => 42,
         "x=40;x=x+2;x" => 42, "x=40;x+=2" => 42, "\\if=40;\\if+2" => 42) {
        .key.&test-eval: .value;
    }
}

subtest "arrays", {
    for ("[10,20]" => [10,20], "x=10;[x, 19+1]" => [10,20], '[10,20,30][1]' => 20) {
        .key.&test-eval: .value;
    }
}

subtest "hashes", {
    for (q`{'a' => 10, "b" => 20}` => %(:a(10),:b(20)), q`x=10;B='b';{'a' => x, B => 19+1}` =>  %(:a(10),:b(20)), q`{'a' => 10, 'b' => 20, 'c' => 30}{'b'}` => 20) {
        .key.&test-eval: .value;
    }
}

done-testing();
