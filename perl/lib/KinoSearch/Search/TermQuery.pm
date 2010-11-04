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

package KinoSearch::Search::TermQuery;
use KinoSearch;

1;

__END__

__BINDING__

my $synopsis = <<'END_SYNOPSIS';
    my $term_query = Lucy::Search::TermQuery->new(
        field => 'content',
        term  => 'foo', 
    );
    my $hits = $searcher->hits( query => $term_query );
END_SYNOPSIS

my $constructor = <<'END_CONSTRUCTOR';
    my $term_query = Lucy::Search::TermQuery->new(
        field => 'content',    # required
        term  => 'foo',        # required
    );
END_CONSTRUCTOR

Clownfish::Binding::Perl::Class->register(
    parcel            => "Lucy",
    class_name        => "KinoSearch::Search::TermQuery",
    bind_methods      => [qw( Get_Field Get_Term )],
    bind_constructors => ["new"],
    make_pod          => {
        synopsis    => $synopsis,
        constructor => { sample => $constructor },
        methods     => [qw( get_field get_term )],
    },
);
Clownfish::Binding::Perl::Class->register(
    parcel            => "Lucy",
    class_name        => "KinoSearch::Search::TermCompiler",
    bind_constructors => ["do_new"],
);


