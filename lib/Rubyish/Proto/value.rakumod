unit module Rubyish::Proto::value;

role Grammar {
    proto token value { * }
    token value:sym<num> { <num=.unsigned-int> | <num=.hex-int> | <num=.decimal-num> }
    token unsigned-int { ['0' <[obd]> '_'?]? <.decint> }
    token decint { [\d+] +% '_' }
    token hex-int {
        '0x' '_'? [
            [ \d | <[ a..f A..F ａ..ｆ Ａ..Ｆ ]> ]+
        ]+ % '_'
    }

    token decimal-num {
        [ <int=.decint> '.' <frac=.decint> ] <.escale>?
        | [ <int=.decint> ] <.escale>
    }

    token escale { <[Ee]> <[+-]>? <.decint> }

    token value:sym<nil>     { <sym> }
    token value:sym<true>    { <sym> }
    token value:sym<false>   { <sym> }
}

role Actions {
    use experimental :rakuast;
    multi sub literal(Int:D $v) { RakuAST::IntLiteral.new($v) }
    multi sub literal(Rat:D $v) { RakuAST::RatLiteral.new($v) }
    multi sub literal(Num:D $v) { RakuAST::NumLiteral.new($v) }

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

}
