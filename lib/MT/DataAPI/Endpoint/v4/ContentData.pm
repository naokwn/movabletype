package MT::DataAPI::Endpoint::v4::ContentData;
use strict;
use warnings;

use MT::ContentStatus;
use MT::DataAPI::Endpoint::Common;
use MT::DataAPI::Resource;
use MT::Util qw( archive_file_for );

sub list {
    my ( $app, $endpoint ) = @_;

    my ( $site, $content_type ) = context_objects(@_) or return;

    my $res = filtered_list( $app, $endpoint, 'content_data' ) or return;

    +{  totalResults => $res->{count} || 0,
        items =>
            MT::DataAPI::Resource::Type::ObjectList->new( $res->{objects} ),
    };
}

sub create {
    my ( $app, $endpoint ) = @_;

    my ( $site, $content_type ) = context_objects(@_) or return;

    my $author = $app->user;

    my $site_perms = $author->permissions( $site->id );

    my $orig_content_data = $app->model('content_data')->new(
        blog_id         => $site->id,
        content_type_id => $content_type->id,
        author_id       => $author->id,
        status          => (
            (          $author->can_do('publish_all_content_data')
                    || $site_perms->can_do('publish_all_content_data')
                    || $site_perms->can_do(
                    'publish_all_content_data_' . $content_type->unique_id
                    )
                    || $site_perms->can_do(
                    'publish_own_content_data_' . $content_type->unique_id
                    )
            )
            ? MT::ContentStatus::RELEASE()
            : MT::ContentStatus::HOLD()
        ),
    );

    my $new_content_data
        = $app->resource_object( 'content_data', $orig_content_data )
        or return;

    my $post_save = _build_post_save_sub( $app, $site, $new_content_data,
        $orig_content_data );

    save_object( $app, 'content_data', $new_content_data ) or return;

    $post_save->();

    $new_content_data;
}

sub get {
    my ( $app, $endpoint ) = @_;

    my ( $site, $content_type, $content_data ) = context_objects(@_);
    return unless $content_data;

    run_permission_filter( $app, 'data_api_view_permission_filter',
        'content_data', $content_data->id, obj_promise($content_data) )
        or return;

    $content_data;
}

sub update {
    my ( $app, $endpoint ) = @_;

    my ( $site, $content_type, $orig_content_data ) = context_objects(@_)
        or return;

    my $new_content_data
        = $app->resource_object( 'content_data', $orig_content_data )
        or return;

    my $post_save = _build_post_save_sub( $app, $site, $new_content_data,
        $orig_content_data );

    save_object(
        $app,
        'content_data',
        $new_content_data,
        $orig_content_data,
        sub {
            $new_content_data->modified_by( $app->user->id );
            $_[0]->();
        }
    ) or return;

    $post_save->();

    $new_content_data;
}

sub delete {
    my ( $app, $endpoint ) = @_;
    my %recipe;

    my ( $site, $content_type, $content_data ) = context_objects(@_)
        or return;

    run_permission_filter( $app, 'data_api_delete_permission_filter',
        'content_data', $content_data )
        or return;

    if ( $content_data->status eq MT::ContentStatus::RELEASE() ) {
        %recipe = $app->publisher->rebuild_deleted_content_data(
            ContentData => $content_data,
            Blog        => $site,
        );
    }

    $content_data->remove()
        or return $app->error(
        $app->tranlsate(
            'Removing [_1] failed: [_2]', $content_data->class_label,
            $content_data->errstr
        ),
        500
        );

    $app->run_callbacks( 'data_api_post_delete.content_data',
        $app, $content_data );

    if ( $app->config('RebuildAtDelete') ) {
        $app->run_callbacks('pre_build');
        MT::Util::start_background_task(
            sub {
                $app->rebuild_archives(
                    Blog   => $site,
                    Recipe => \%recipe,
                ) or return $app->publish_error();
                $app->rebuild_indexes( Blog => $site )
                    or return $app->publish_error();
                $app->run_callbacks( 'rebuild', $site );
            }
        );
    }

    $content_data;
}

sub _build_post_save_sub {
    my ( $app, $site, $obj, $orig_obj ) = @_;

    my $archive_type = 'ContentType';
    my $orig_file
        = $orig_obj->id
        ? archive_file_for( $orig_obj, $site, $archive_type )
        : undef;

    my ( $previous_old, $next_old );
    if (   $orig_obj->id
        && $obj->authored_on != $orig_obj->authored_on )
    {
        $previous_old = $orig_obj->previous(1);
        $next_old     = $orig_obj->next(1);
    }

    return sub { }
        unless ( $obj->status || 0 ) == MT::ContentStatus::RELEASE()
        || $orig_obj->status == MT::ContentStatus::RELEASE();

    return sub {
        if ( $app->config('DeleteFilesAtRebuild') && defined $orig_file ) {
            my $file = archive_file_for( $obj, $site, $archive_type );
            if (   $file ne $orig_file
                || $obj->status != MT::ContentStatus::RELEASE() )
            {
                $app->publisher->remove_content_data_archive_file(
                    ContentData => $orig_obj,
                    ArchiveType => $archive_type,
                    Force       => 0,
                );
            }
        }

        MT::Util::start_background_task(
            sub {
                $app->run_callbacks('pre_build');
                $app->rebuild_content_data(
                    ContentData       => $obj,
                    BuildDependencies => 1,
                    OldPrevious       => $previous_old ? $previous_old->id
                    : undef,
                    OldNext => $next_old ? $next_old->id
                    : undef,
                ) or return $app->publish_error();
                $app->run_callbacks( 'rebuild', $site );
                $app->run_callbacks('post_build');
                1;
            }
        );
    };
}

1;

