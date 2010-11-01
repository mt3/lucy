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
use lib 'buildlib';

use Test::More tests => 6;
use KinoSearch::Test::TestUtils qw( test_analyzer );

my $stopalizer = KinoSearch::Analysis::Stopalizer->new( language => 'en' );
test_analyzer( $stopalizer, 'the', [], "single stopword stopalized" );

my $tokenizer    = KinoSearch::Analysis::Tokenizer->new;
my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new(
    analyzers => [ $tokenizer, $stopalizer ], );
test_analyzer( $polyanalyzer, 'i am the walrus',
    ['walrus'], "multiple stopwords stopalized" );
