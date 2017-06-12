use strict;
use warnings;

use Test::More;

use lib qw( lib extlib t/lib );
use MT;
use MT::Test qw( :db );

use MT::ContentField;

subtest 'unique_id' => sub {
    my $cf = MT::ContentField->new;
    $cf->set_values(
        {   blog_id         => 1,
            content_type_id => 1,
        }
    );

    $cf->unique_id('123');
    is( $cf->unique_id, undef, 'cannot set unique_id' );

    $cf->save or die $cf->errstr;
    ok( $cf->unique_id, 'set unique_id after save' );
    is( length $cf->unique_id, 40, 'length of unique_id is 40' );

    my $unique_id = $cf->unique_id;
    $cf->unique_id( $unique_id . '456' );
    is( $cf->unique_id, $unique_id, 'cannot set unique_id' );

    my $cf2 = MT::ContentField->new;
    $cf2->set_values(
        {   blog_id         => 1,
            content_type_id => 1,
        }
    );
    $cf2->save or die $cf2->errstr;
    $cf2->column( 'unique_id', $cf->unique_id );
    $cf2->save;
    ok( $cf2->errstr, 'unique_id column must be unique' );
};

done_testing;
