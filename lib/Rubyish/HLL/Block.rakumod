unit class Rubyish::HLL::Block;

use Rubyish::HLL::Symbol;
has Rubyish::HLL::Symbol %!symbol;

method symbol(Str:D $name) {
    %!symbol{$name} //= Rubyish::HLL::Symbol.new;
}
