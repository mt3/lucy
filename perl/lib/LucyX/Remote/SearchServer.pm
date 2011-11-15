# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

package LucyX::Remote::SearchServer;
BEGIN { our @ISA = qw( Lucy::Object::Obj ) }
use Carp;
use Storable qw( nfreeze thaw );
use Scalar::Util qw( reftype );

# Inside-out member vars.
our %searcher;
our %port;
our %password;
our %sock;

use IO::Socket::INET;
use IO::Select;

sub new {
    my ( $either, %args ) = @_;
    my $searcher = delete $args{searcher};
    my $password = delete $args{password};
    my $port     = delete $args{port};
    my $self     = $either->SUPER::new(%args);
    $searcher{$$self} = $searcher;
    confess("Missing required param 'password'") unless defined $password;
    $password{$$self} = $password;

    # Establish a listening socket.
    $port{$$self} = $port;
    confess("Invalid port: $port") unless $port =~ /^\d+$/;
    my $sock = IO::Socket::INET->new(
        LocalPort => $port,
        Proto     => 'tcp',
        Listen    => SOMAXCONN,
        Reuse     => 1,
    );
    confess("No socket: $!") unless $sock;
    $sock{$$self} = $sock;

    return $self;
}

sub DESTROY {
    my $self = shift;
    delete $searcher{$$self};
    delete $port{$$self};
    delete $password{$$self};
    delete $sock{$$self};
    $self->SUPER::DESTROY;
}

my %dispatch = (
    handshake     => \&do_handshake,
    terminate     => \&do_terminate,
    doc_max       => \&do_doc_max,
    doc_freq      => \&do_doc_freq,
    top_docs      => \&do_top_docs,
    fetch_doc     => \&do_fetch_doc,
    fetch_doc_vec => \&do_fetch_doc_vec,
);

sub serve {
    my $self      = shift;
    my $main_sock = $sock{$$self};
    my $read_set  = IO::Select->new($main_sock);

    while ( my @ready = $read_set->can_read ) {
        for my $readhandle (@ready) {
            # If this is the main handle, we have a new client, so accept.
            if ( $readhandle == $main_sock ) {
                my $client_sock = $main_sock->accept;
                $read_set->add($client_sock);
            }
            # Otherwise it's a client sock, so process the request.
            else {
                my $client_sock = $readhandle;
                my ( $check_val, $buf, $len );
                $check_val = $client_sock->sysread( $buf, 4 );
                if ( $check_val == 0 ) {
                    # If sysread returns 0, socket has been closed cleanly at
                    # the other end.
                    $read_set->remove($client_sock);
                    next;
                }
                confess $! unless $check_val == 4;
                $len = unpack( 'N', $buf );
                $check_val = $client_sock->sysread( $buf, $len );
                confess $! unless $check_val == $len;
                my $args = eval { thaw($buf) };
                confess $@ if $@;
                confess "Not a hashref" unless reftype($args) eq 'HASH';
                my $method = delete $args->{_action};

                # If "done", the client's closing.
                if ( $method eq 'done' ) {
                    $read_set->remove($client_sock);
                    $client_sock->close;
                    next;
                }

                # Process the method call.
                $dispatch{$method} or confess "ERROR: Bad method name: $method\n";
                my $response   = $dispatch{$method}->( $self, $args );
                my $frozen     = nfreeze($response);
                my $packed_len = pack( 'N', length($frozen) );
                $check_val = $client_sock->syswrite("$packed_len$frozen");
                confess $! unless $check_val == length($frozen) + 4;

                # Remote signal to close the server.
                if ( $method eq 'terminate' ) {
                    my @all_handles = $read_set->handles;
                    $read_set->remove(\@all_handles);
                    $client_sock->close;
                    $main_sock->close;
                    return;
                }
            }
        }
    }
}

sub do_handshake {
    my ( $self, $args ) = @_;
    return { retval => $password{$$self} eq $args->{password} };
}

sub do_terminate {
    return { retval => 1 };
}

sub do_doc_freq {
    my ( $self, $args ) = @_;
    return { retval => $searcher{$$self}->doc_freq(%$args) };
}

sub do_top_docs {
    my ( $self, $args ) = @_;
    my $top_docs = $searcher{$$self}->top_docs(%$args);
    return { retval => $top_docs };
}

sub do_doc_max {
    my ( $self, $args ) = @_;
    my $doc_max = $searcher{$$self}->doc_max;
    return { retval => $doc_max };
}

sub do_fetch_doc {
    my ( $self, $args ) = @_;
    my $doc = $searcher{$$self}->fetch_doc( $args->{doc_id} );
    return { retval => $doc };
}

sub do_fetch_doc_vec {
    my ( $self, $args ) = @_;
    my $doc_vec = $searcher{$$self}->fetch_doc_vec( $args->{doc_id} );
    return { retval => $doc_vec };
}

1;

__END__

=head1 NAME

LucyX::Remote::SearchServer - Make a Searcher remotely accessible.

=head1 SYNOPSIS

    my $searcher = Lucy::Search::IndexSearcher->new( 
        index => '/path/to/index' 
    );
    my $search_server = LucyX::Remote::SearchServer->new(
        searcher => $searcher,
        port       => 7890,
        password   => $pass,
    );
    $search_server->serve;

=head1 DESCRIPTION 

The SearchServer class, in conjunction with
L<SearchClient|LucyX::Remote::SearchClient>, makes it possible to run
a search on one machine and report results on another.  

By aggregating several SearchClients under a
L<PolySearcher|Lucy::Search::PolySearcher>, the cost of searching
what might have been a prohibitively large monolithic index can be distributed
across multiple nodes, each with its own, smaller index.

=head1 METHODS

=head2 new

    my $search_server = LucyX::Remote::SearchServer->new(
        searcher => $searcher, # required
        port       => 7890,      # required
        password   => $pass,     # required
    );

Constructor.  Takes hash-style parameters.

=over

=item *

B<searcher> - the L<Searcher|Lucy::Search::IndexSearcher> that the SearchServer
will wrap.

=item *

B<port> - the port on localhost that the server should open and listen on.

=item *

B<password> - a password which must be supplied by clients.

=back

=head2 serve

    $search_server->serve;

Open a listening socket on localhost and wait for SearchClients to connect.

=cut
