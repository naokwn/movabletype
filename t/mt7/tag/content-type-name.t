use strict;
use warnings;

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";    # t/lib
use Test::More;
use MT::Test::Env;
our $test_env;

BEGIN {
    $test_env = MT::Test::Env->new;
    $ENV{MT_CONFIG} = $test_env->config_file;
}

use MT::Test::Tag;

# plan tests => 2 * blocks;
plan tests => 1 * blocks;

use MT;
use MT::Test;
use MT::Test::Permission;
my $app = MT->instance;

my $blog_id = 1;

filters {
    template => [qw( chomp )],
    expected => [qw( chomp )],
    error    => [qw( chomp )],
};

$test_env->prepare_fixture('db');

my $ct = MT::Test::Permission->make_content_type(
    name    => 'test content type',
    blog_id => $blog_id,
);
MT::Test::Permission->make_content_data(
    blog_id         => $blog_id,
    content_type_id => $ct->id,
);

MT::Test::Tag->run_perl_tests($blog_id);

# MT::Test::Tag->run_php_tests($blog_id);

__END__

=== MT::ContentTypeName
--- template
<MTContents content_type="test content type"><MTContentTypeName></MTContents>
--- expected
test content type
