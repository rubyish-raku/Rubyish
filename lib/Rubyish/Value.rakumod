unit module Rubyish::Value;

role Grammar {
    proto token value { * }
    token value:sym<num> { <num=.unsigned-int> | <num=.hex-int> | <num=.decimal-num> }
    token unsigned-int { ['0' <[obd]> '_'?]? <.decint> }
    token decint { [\d+] +% '_' }
    token hex-int {
        '0x' '_'? <.hexdigits>
    }
    token hexdigits {
        [ \d | <[ a..f A..F ａ..ｆ Ａ..Ｆ ]> ]+ % '_'
    }
    token decimal-num {
        [ <int=.decint> '.' <frac=.decint> ] <.escale>?
        | [ <int=.decint> ] <.escale>
    }

    token escale { <[Ee]> <[+-]>? <.decint> }

    token value:sym<nil>     { <sym> }
    token value:sym<true>    { <sym> }
    token value:sym<false>   { <sym> }
    token value:sym<string>  { <string> }

    proto token string {*}
    token string:sym<'> {<sym> ~ <sym> ['\\'$<lit>=<['\\]>||$<lit>=<-[\\'\n]>+]+}

    token string:sym<"> {<sym> ~ <sym> <segment>*}
    proto token segment {*}
    token segment:sym<expr> { '#{' ~ '}' <stmtlist> }
    token segment:sym<esc>  { '\\' [<escape>||.] }
    token segment:sym<reg>  {[<!before ['#{' | '"' | \n | '\\']>.]+}

    proto token escape {*}
    token escape:sym<char>      { <[abtnvfres"\\\n]> }
    token escape:sym<octal>     { <[0..7]>**1..3 }
    token escape:sym<control>   { <[Cc]>$<chr>=<[a..z A..Z]> }
    token escape:sym<hex>       { <[xX]>$<num>=[<xdigit>**4] }
    token escape:sym<unicode>   { <[uU]>$<num>=[<xdigit>**1..6] }
}

role Actions {
    use experimental :rakuast;
    multi sub literal(Int:D $v) { RakuAST::IntLiteral.new($v) }
    multi sub literal(Rat:D $v) { RakuAST::RatLiteral.new($v) }
    multi sub literal(Num:D $v) { RakuAST::NumLiteral.new($v) }
    multi sub literal(Str:D $v) { RakuAST::StrLiteral.new($v) }
    sub blockoid(RakuAST::StatementList:D $stmts) { RakuAST::Blockoid.new: $stmts }
    sub block(RakuAST::Blockoid:D $body) { RakuAST::Block.new: :$body }

    method value:sym<num>($/) { make $<num>.ast }
    method unsigned-int($/) { make $/.Int.&literal }
    method hex-int($/) { make $/.Int.&literal }
    method decimal-num($/) { make $/.Numeric.&literal }
    method value:sym<nil>($/) {
        make RakuAST::Type::Simple.new(
            RakuAST::Name.from-identifier("Nil")
        )
    }
    method value:sym<true>($/) {
        make RakuAST::Term::Enum.from-identifier('True');
    }
    method value:sym<false>($/) {
        make RakuAST::Term::Enum.from-identifier('False');
    }
    method value:sym<string>($/) { make $<string>.ast }
    method string:sym<'>($/) {
        make @<lit>.join.&literal;
    }
    method string:sym<">(Capture $/) {
        my @segments = @<segment>>>.ast;
        make RakuAST::QuotedString.new: :@segments;
    }
    method segment:sym<expr>($/) { make $<stmtlist>.ast.&blockoid.&block }
    method segment:sym<esc>($/)  { make literal($<escape> ?? $<escape>.ast !! $/.Str) }
    method segment:sym<reg>($/)  { make literal($/.Str) }

    method escape:sym<char>($/) {
        my constant %ESC = %(
            'a'  => "\a",
            'b'  => "\b",
            't'  => "\t",
            'n'  => "\n",
            'v'  => 0xB.chr,
            'f'  => "\f",
            'r'  => "\r",
            'e'  => "\e",
            's'  => " ",
            '"'  => '"',
            '\\' => '\\',
            "\n" => '', # continuation
        );
        make %ESC{$/.Str};
    }
    method escape:sym<octal>($/)    { make chr(:8($/.Str)) }
    method escape:sym<control>($/)  { make ($<chr>.lc.ord - 'a'.ord).chr }
    method escape:sym<hex>($/)      { make chr(:16($<num>.Str)) }
    method escape:sym<unicode>($/)  { make chr(:16($<num>.Str)) }
}
