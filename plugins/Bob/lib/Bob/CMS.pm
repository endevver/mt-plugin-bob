#############################################################################
# Copyright © 2008-2009 Six Apart Ltd.
# This program is free software: you can redistribute it and/or modify it
# under the terms of version 2 of the GNU General Public License as published
# by the Free Software Foundation, or (at your option) any later version.
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# version 2 for more details.  You should have received a copy of the GNU
# General Public License version 2 along with this program. If not, see
# <http://www.gnu.org/licenses/>.

package Bob::CMS;

use strict;
use warnings;
use Bob::Job;
use Bob::Util qw( get_type_data get_frequency_data );

use MT::Blog;
use MT::Util qw( format_ts );

# The Listing screen for MT4.
sub list_jobs {
    my ($app) = @_;

    my $blog   = $app->blog;
    my $plugin = MT->component('Bob');
    my %blog_names;
    my $blog_iter = MT::Blog->load_iter();
    while ( my $b = $blog_iter->() ) {
        $blog_names{ $b->id } = $b->name;
    }
    my $types_display = get_type_data();
    my $freq_display  = get_frequency_data();

    my $params = {
        ($app->param('saved')           ? (saved            => 1) : ()),
        ($app->param('saved_deleted')   ? (saved_deleted    => 1) : ()),
    };

    $app->listing(
        {   type     => 'bob_job',
            template => 'list_bob_job.tmpl',
            params   => $params,

            # args  => {
            #     sort      => 'identifier',
            #     direction => 'descend'
            # },
            code => sub {
                my ( $job, $row ) = @_;
                $row->{blog_name}    = $blog_names{ $job->blog_id };
                $row->{type_display} = $types_display->{ $job->type };
                $row->{frequency_display}
                    = $freq_display->{ $job->frequency };
                if ( $job->is_active ) {
                    $row->{is_active} = 'Y';
                }
                else {
                    $row->{is_active} = 'N';
                }

                if ( $job->last_run ) {
                    $row->{formatted_last_run}
                        = format_ts( '%d %b %Y %H:%M', $job->last_run );
                }
                else {
                    $row->{formatted_last_run} = 'N/A';
                }
            },
        }
    );
}

sub edit_job {
    my ($app)  = @_;
    my $q      = $app->param;
    my $plugin = MT->component('Bob');
    my $tmpl   = $plugin->load_tmpl('edit_bob_job.tmpl');

    if ( $app->param('deleted') ) {
        _redirect_to_listing({
            app => $app,
            key => 'deleted',
        });
    }

    my $param;
    my ( $job, $frequency, $type );
    if ( $app->param('id') ) {
        $job       = Bob::Job->load( $app->param('id') );
        $frequency = $job->frequency;
        $type      = $job->type;
        my $blog = MT::Blog->load( $job->blog_id );
        $param->{blog_name} = $blog->name;
        $param->{blog_id}   = $blog->id;
        $param->{is_active} = $job->is_active;
        $param->{id}        = $job->id;

        $param->{last_run}  = format_ts( '%d %b %Y %H:%M', $job->last_run );
        $param->{next_run}  = format_ts( '%d %b %Y %H:%M', $job->next_run );
    }
    else {
        my @blogs_loop;
        my @blogs = MT::Blog->load({ class => '*', });
        foreach my $blog (@blogs) {
            my $row;
            $row->{blog_id}   = $blog->id;
            $row->{blog_name} = $blog->name;
            if ($job) {
                if ( $job->blog_id == $blog->id ) {
                    $row->{selected} = 1;
                }
            }
            push @blogs_loop, $row;
        }
        $param->{blogs_loop} = \@blogs_loop;

        # A default frequency value of 1440 minutes (1 day/24 hours) is a safe
        # starting point.
        $frequency = 1440;
    }
    $param->{object_label}        = Bob::Job->class_label;
    $param->{object_label_plural} = Bob::Job->class_label_plural;
    $param->{object_type}         = Bob::Job->class_type;
    $param->{frequencies_loop}
        = get_frequency_data( 'frequency_value', 'frequency_name', $frequency );
    $param->{types_loop}
        = get_type_data( 'type_value', 'type_name', $type );

    $param->{saved} = $q->param('saved_changes');

    return $app->build_page( $tmpl, $param );
}

sub save_job {
    my $app = shift;

    # If the "Active" checkbox is unchecked (meaning making this job inactive)
    # then be sure to set a value for this parameter.
    my $active = $app->param('is_active') || '0';
    $app->param('is_active', $active);

    $app->forward('save');
}

# Delete a rebuilder job, either from the listing or edit screen.
sub delete_job {
    my ($app) = @_;
    my $q     = $app->can('query') ? $app->query : $app->param;

    $app->validate_magic or return;

    my @ids = $q->param('id');
    for my $id (@ids) {
        my $job = MT->model('bob_job')->load($id) or next;
        $job->remove;
    }
    $app->add_return_arg( deleted => 1 );
    $app->call_return;
}

# After deleting or saving, return to the listing screen. However, be sure to
# redirect to the correct URL based on the version of MT.
sub _redirect_to_listing {
    my ($arg_ref) = @_;
    my $app = $arg_ref->{app};
    my $key = $arg_ref->{key};

    # MT5
    if ( $app->product_version =~ /^5/ ) {
        return $app->redirect(
            $app->uri(
                mode => 'list',
                args => {
                    _type   => 'bob_job',
                    blog_id => 0,
                    $key    => 1,
                },
            )
        );
    }
    # MT4
    else {
        return $app->redirect(
            $app->uri(
                mode => 'rebuilder_list',
                args => {
                    blog_id => 0,
                    $key    => 1,
                },
            )
        );
    }
}

sub cms_job_presave_callback {
    my ( $cb, $app, $job, $orig ) = @_;
    #unless ( $app->{query}->{is_active} ) {
        #$job->is_active(0);
    #}
    return 1;
}

sub cms_job_postsave_callback {
    my ( $cb, $app, $job, $orig ) = @_;
    use MT::TheSchwartz::FuncMap;
    my @funcmaps = MT::TheSchwartz::FuncMap->load(
        { funcname => 'Bob::Worker::Rebuilder' } );
    my $funcmap = pop @funcmaps;
    if ($funcmap) {
        use MT::TheSchwartz::Job;
        my @queued = MT::TheSchwartz::Job->load(
            { uniqkey => $job->id, funcid => $funcmap->funcid } );
        foreach my $qd (@queued) {
            $qd->remove;
        }
    }
    if ( $job->is_active ) {
        $job->inject_worker;
    }
    return 1;
}

# If the Create and Manage plugin is installed in MT5 (and thereby the Manage
# menu exists), then we *don't* want to show the link to Bob the Rebuilder
# there and need to explicitly hide it: just check if this is MT5
sub mt5_menu_condition {
    # This is MT4.x; display the Manage > Rebuilder menu item.
    return 1 if MT->product_version =~ /^4/;
    # This is MT5; don't display Manage > Rebuilder because it exists at
    # Settings > Rebuilder.
    return 0;
}

1;
