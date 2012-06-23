use strict;
use Test::More;

require Inline::JSX;

for my $t (
    [ 'II' =>  ['I','I'] ],
    [ 'NN' =>  ['N','N'] ],
    [ 'SI' =>  ['S','I'] ],
    [ 'AX' =>  [['A','X']] ],
    [ 'ANN' => [['A','N'],'N'] ],
    [ 'HI'  => [['H','I']] ],
    [ 'IAAI' => ['I',['A',['A','I']]] ],
    [ 'LPoint$' => [['L','Point']] ],
    [ 'LPoint$LPoint$' => [['L','Point'],['L','Point']] ],
    [ 'HLPoint$' => [['H',['L','Point']]] ],
    [ 'ASLPoint$ULPoint$' => [['A','S'],['L','Point'],['U',['L','Point']]] ],
    [ 'F$IS$I' => [['F','I','S'],'I'] ],
    [ 'F$IS$II' => [['F','I','S'],'I','I'] ],
    [ 'F$IIS$I' => [['F','I','I','S'],'I'] ],
    [ 'F$LPoint$IS$LPoint$I' => [['F',['L','Point'],'I','S'],['L','Point'],'I'] ],
    [ 'F$IF$IS$$I' => [['F','I',['F','I','S']],'I'] ],
) {
    my ( $str, $exp ) = @$t;
    is_deeply Inline::JSX::parse_type( $str )->[1], $exp, $str;
}


done_testing;


