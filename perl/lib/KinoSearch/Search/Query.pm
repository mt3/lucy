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

package KinoSearch::Search::Query;
use KinoSearch;

1;

__END__

__BINDING__

my $synopsis = <<'END_SYNOPSIS';
    # Query is an abstract base class.
    package MyQuery;
    use base qw( KinoSearch::Search::Query );
    
    sub make_compiler {
        my $self = shift;
        return MyCompiler->new( @_, parent => $self );
    }
    
    package MyCompiler;
    use base ( KinoSearch::Search::Compiler );
    ...
END_SYNOPSIS

my $constructor = <<'END_CONSTRUCTOR_CODE_SAMPLE';
    my $query = MyQuery->SUPER::new(
        boost => 2.5,
    );
END_CONSTRUCTOR_CODE_SAMPLE

Clownfish::Binding::Perl::Class->register(
    parcel       => "KinoSearch",
    class_name   => "KinoSearch::Search::Query",
    bind_methods => [
        qw( Set_Boost
            Get_Boost
            _make_compiler|Make_Compiler )
    ],
    bind_constructors => ["new"],
    make_pod          => {
        synopsis    => $synopsis,
        constructor => { sample => $constructor },
        methods     => [qw( make_compiler set_boost get_boost )],
    },
);

