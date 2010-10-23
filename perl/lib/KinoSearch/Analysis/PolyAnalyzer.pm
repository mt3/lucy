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

package KinoSearch::Analysis::PolyAnalyzer;
use KinoSearch;

1;

__END__

__BINDING__

my $synopsis = <<'END_SYNOPSIS';
    my $schema = KinoSearch::Plan::Schema->new;
    my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new( 
        language => 'en',
    );
    my $type = KinoSearch::Plan::FullTextType->new(
        analyzer => $polyanalyzer,
    );
    $schema->spec_field( name => 'title',   type => $type );
    $schema->spec_field( name => 'content', type => $type );
END_SYNOPSIS

my $constructor = <<'END_CONSTRUCTOR';
    my $analyzer = KinoSearch::Analysis::PolyAnalyzer->new(
        language  => 'es',
    );
    
    # or...

    my $case_folder  = KinoSearch::Analysis::CaseFolder->new;
    my $tokenizer    = KinoSearch::Analysis::Tokenizer->new;
    my $stemmer      = KinoSearch::Analysis::Stemmer->new( language => 'en' );
    my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $whitespace_tokenizer, $stemmer, ], );
END_CONSTRUCTOR

Clownfish::Binding::Perl::Class->register(
    parcel            => "KinoSearch",
    class_name        => "KinoSearch::Analysis::PolyAnalyzer",
    bind_constructors => ["new"],
    bind_methods      => [qw( Get_Analyzers )],
    make_pod          => {
        methods     => [qw( get_analyzers )],
        synopsis    => $synopsis,
        constructor => { sample => $constructor },
    },
);


