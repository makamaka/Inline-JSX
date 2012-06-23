package t::Utils;

use strict;
use Test::More;
use File::Path qw(remove_tree);

BEGIN {
    mkdir('_Inline_test', 0755) unless -e '_Inlne_test';
    unless ( $ENV{ PERL_INLINE_JSX_JSX_PATH } ) {
        $ENV{ PERL_INLINE_JSX_JSX_PATH } = do 't/jsx_path.pl';
    }
    unless ( -e $ENV{ PERL_INLINE_JSX_JSX_PATH } ) {
        plan skip_all => "jsx is not found.";
    }
}


END {
    remove_tree('_Inline_test') if -e '_Inline_test';
}


1;

