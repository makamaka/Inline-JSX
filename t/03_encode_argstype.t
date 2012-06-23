use strict;
use Test::More;
use Time::Piece;

require Inline::JSX;

my $p = bless {}, 'Point';

for my $t (
    [ [undef] => ['U'] ],
    [ [1 ,2] => ['I','I'] ],
    [ [1.1, 0.3] =>  ['N','N'] ],
    [ [1 ,"a"] => ['I','S'] ],
    [ [[1]] => [['A','I']] ],
    [ [1, [1.0], 2.5] => ['I',['A','N'],'N'] ],
    [ [{'foo'=>'bar'}] => [['H','S']] ],
    [ [{'foo'=>['foo']}] => [['H',['A','S']]] ],
    [ [$p] => [['L',$p]] ],
    [ [$p, $p] => [['L',$p],['L',$p]] ],
    [ [[$p, $p]] => [['A',['L',$p]]] ],
    [ [sub {}], ['F'] ],
    [ [qr/ab/] => [['L','RegExp']] ],
    [ [scalar(Time::Piece::localtime())] => [['L','Date']] ],
    [ [Inline::JSX->null] => ['!'] ],
) {
    my ( $objs, $exp ) = @$t;
    is_deeply Inline::JSX::encode_argstype( @$objs ), $exp;
}


done_testing;


