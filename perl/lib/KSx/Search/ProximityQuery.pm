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

package KSx::Search::ProximityQuery;
use KinoSearch;

1;

__END__

__BINDING__

my $synopsis = <<'END_SYNOPSIS';
    my $proximity_query = KSx::Search::ProximityQuery->new( 
        field  => 'content',
        terms  => [qw( the who )],
        within => 10,    # match within 10 positions
    );
    my $hits = $searcher->hits( query => $proximity_query );
END_SYNOPSIS

Clownfish::Binding::Perl::Class->register(
    parcel            => "KinoSearch",
    class_name        => "KSx::Search::ProximityQuery",
    bind_methods      => [qw( Get_Field Get_Terms )],
    bind_constructors => ["new"],
    make_pod          => {
        constructor => { sample => '' },
        synopsis    => $synopsis,
        methods     => [qw( get_field get_terms get_within )],
    },
);
Clownfish::Binding::Perl::Class->register(
    parcel            => "KinoSearch",
    class_name        => "KSx::Search::ProximityCompiler",
    bind_constructors => ["do_new"],
);

