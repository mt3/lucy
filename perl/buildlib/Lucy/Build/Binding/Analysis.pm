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
package Lucy::Build::Binding::Analysis;
use strict;
use warnings;

sub bind_all {
    my $class = shift;
    $class->bind_analyzer;
    $class->bind_casefolder;
    $class->bind_easyanalyzer;
    $class->bind_inversion;
    $class->bind_normalizer;
    $class->bind_polyanalyzer;
    $class->bind_regextokenizer;
    $class->bind_snowballstemmer;
    $class->bind_snowballstopfilter;
    $class->bind_standardtokenizer;
    $class->bind_token;
}

sub bind_analyzer {
    my @bound = qw( Transform Transform_Text Split );

    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    $pod_spec->set_synopsis("    # Abstract base class.\n");

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::Analyzer",
    );
    $binding->bind_constructor;
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_casefolder {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $case_folder = Lucy::Analysis::CaseFolder->new;

    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $tokenizer, $stemmer ],
    );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $case_folder = Lucy::Analysis::CaseFolder->new;
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::CaseFolder",
    );
    $binding->bind_constructor;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_easyanalyzer {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $schema = Lucy::Plan::Schema->new;
    my $analyzer = Lucy::Analysis::EasyAnalyzer->new(
        language => 'en',
    );
    my $type = Lucy::Plan::FullTextType->new(
        analyzer => $analyzer,
    );
    $schema->spec_field( name => 'title',   type => $type );
    $schema->spec_field( name => 'content', type => $type );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $analyzer = Lucy::Analysis::EasyAnalyzer->new(
        language  => 'es',
    );
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor, );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::EasyAnalyzer",
    );
    $binding->bind_constructor;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_inversion {
    my @bound = qw( Append Reset Invert Next );

    my $xs = <<'END_XS';
MODULE = Lucy   PACKAGE = Lucy::Analysis::Inversion

SV*
new(...)
CODE:
{
    lucy_Token *starter_token = NULL;
    // parse params, only if there's more than one arg
    if (items > 1) {
        SV *text_sv = NULL;
        chy_bool_t args_ok
            = XSBind_allot_params(&(ST(0)), 1, items,
                                  "Lucy::Analysis::Inversion::new_PARAMS",
                                  ALLOT_SV(&text_sv, "text", 4, false),
                                  NULL);
        if (!args_ok) {
            CFISH_RETHROW(CFISH_INCREF(cfish_Err_get_error()));
        }
        if (XSBind_sv_defined(text_sv)) {
            STRLEN len;
            char *text = SvPVutf8(text_sv, len);
            starter_token = lucy_Token_new(text, len, 0, len, 1.0, 1);
        }
    }

    RETVAL = CFISH_OBJ_TO_SV_NOINC(lucy_Inversion_new(starter_token));
    CFISH_DECREF(starter_token);
}
OUTPUT: RETVAL
END_XS

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel       => "Lucy",
        class_name   => "Lucy::Analysis::Inversion",
        xs_code      => $xs,
    );
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_normalizer {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $normalizer = Lucy::Analysis::Normalizer->new;
    
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $normalizer, $tokenizer, $stemmer ],
    );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $normalizer = Lucy::Analysis::Normalizer->new(
        normalization_form => 'NFKC',
        case_fold          => 1,
        strip_accents      => 0,
    );
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::Normalizer",
    );
    $binding->bind_constructor;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_polyanalyzer {
    my @exposed = qw( Get_Analyzers );
    my @bound   = @exposed;

    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $schema = Lucy::Plan::Schema->new;
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new( 
        language => 'en',
    );
    my $type = Lucy::Plan::FullTextType->new(
        analyzer => $polyanalyzer,
    );
    $schema->spec_field( name => 'title',   type => $type );
    $schema->spec_field( name => 'content', type => $type );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $analyzer = Lucy::Analysis::PolyAnalyzer->new(
        language  => 'es',
    );
    
    # or...

    my $case_folder  = Lucy::Analysis::CaseFolder->new;
    my $tokenizer    = Lucy::Analysis::RegexTokenizer->new;
    my $stemmer      = Lucy::Analysis::SnowballStemmer->new( language => 'en' );
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $whitespace_tokenizer, $stemmer, ], );
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );
    $pod_spec->add_method( method => $_, alias => lc($_) ) for @exposed;

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::PolyAnalyzer",
    );
    $binding->bind_constructor;
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_regextokenizer {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $whitespace_tokenizer
        = Lucy::Analysis::RegexTokenizer->new( pattern => '\S+' );

    # or...
    my $word_char_tokenizer
        = Lucy::Analysis::RegexTokenizer->new( pattern => '\w+' );

    # or...
    my $apostrophising_tokenizer = Lucy::Analysis::RegexTokenizer->new;

    # Then... once you have a tokenizer, put it into a PolyAnalyzer:
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $word_char_tokenizer, $stemmer ], );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $word_char_tokenizer = Lucy::Analysis::RegexTokenizer->new(
        pattern => '\w+',    # required
    );
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::RegexTokenizer",
    );
    $binding->bind_constructor( alias => '_new' );
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_snowballstemmer {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $stemmer = Lucy::Analysis::SnowballStemmer->new( language => 'es' );
    
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $tokenizer, $stemmer ],
    );

This class is a wrapper around the Snowball stemming library, so it supports
the same languages.  
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $stemmer = Lucy::Analysis::SnowballStemmer->new( language => 'es' );
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::SnowballStemmer",
    );
    $binding->bind_constructor;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_snowballstopfilter {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $stopfilter = Lucy::Analysis::SnowballStopFilter->new(
        language => 'fr',
    );
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $tokenizer, $stopfilter, $stemmer ],
    );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $stopfilter = Lucy::Analysis::SnowballStopFilter->new(
        language => 'de',
    );
    
    # or...
    my $stopfilter = Lucy::Analysis::SnowballStopFilter->new(
        stoplist => \%stoplist,
    );
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::SnowballStopFilter",
    );
    $binding->bind_constructor;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_standardtokenizer {
    my $pod_spec = Clownfish::CFC::Binding::Perl::Pod->new;
    my $synopsis = <<'END_SYNOPSIS';
    my $tokenizer = Lucy::Analysis::StandardTokenizer->new;

    # Then... once you have a tokenizer, put it into a PolyAnalyzer:
    my $polyanalyzer = Lucy::Analysis::PolyAnalyzer->new(
        analyzers => [ $case_folder, $tokenizer, $stemmer ], );
END_SYNOPSIS
    my $constructor = <<'END_CONSTRUCTOR';
    my $tokenizer = Lucy::Analysis::StandardTokenizer->new;
END_CONSTRUCTOR
    $pod_spec->set_synopsis($synopsis);
    $pod_spec->add_constructor( alias => 'new', sample => $constructor );

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::StandardTokenizer",
    );
    $binding->bind_constructor;
    $binding->set_pod_spec($pod_spec);

    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

sub bind_token {
    my @bound = qw(
        Get_Start_Offset
        Get_End_Offset
        Get_Boost
        Get_Pos_Inc
    );

    my $xs = <<'END_XS';
MODULE = Lucy    PACKAGE = Lucy::Analysis::Token

SV*
new(either_sv, ...)
    SV *either_sv;
CODE:
{
    SV       *text_sv   = NULL;
    uint32_t  start_off = 0;
    uint32_t  end_off   = 0;
    int32_t   pos_inc   = 1;
    float     boost     = 1.0f;

    chy_bool_t args_ok
        = XSBind_allot_params(&(ST(0)), 1, items,
                              "Lucy::Analysis::Token::new_PARAMS",
                              ALLOT_SV(&text_sv, "text", 4, true),
                              ALLOT_U32(&start_off, "start_offset", 12, true),
                              ALLOT_U32(&end_off, "end_offset", 10, true),
                              ALLOT_I32(&pos_inc, "pos_inc", 7, false),
                              ALLOT_F32(&boost, "boost", 5, false),
                              NULL);
    if (!args_ok) {
        CFISH_RETHROW(CFISH_INCREF(cfish_Err_get_error()));
    }

    STRLEN      len;
    char       *text = SvPVutf8(text_sv, len);
    lucy_Token *self = (lucy_Token*)XSBind_new_blank_obj(either_sv);
    lucy_Token_init(self, text, len, start_off, end_off, boost,
                    pos_inc);
    RETVAL = CFISH_OBJ_TO_SV_NOINC(self);
}
OUTPUT: RETVAL

SV*
get_text(self)
    lucy_Token *self;
CODE:
    RETVAL = newSVpvn(Lucy_Token_Get_Text(self), Lucy_Token_Get_Len(self));
    SvUTF8_on(RETVAL);
OUTPUT: RETVAL

void
set_text(self, sv)
    lucy_Token *self;
    SV *sv;
PPCODE:
{
    STRLEN len;
    char *ptr = SvPVutf8(sv, len);
    Lucy_Token_Set_Text(self, ptr, len);
}
END_XS

    my $binding = Clownfish::CFC::Binding::Perl::Class->new(
        parcel     => "Lucy",
        class_name => "Lucy::Analysis::Token",
        xs_code    => $xs,
    );
    $binding->bind_method( method => $_, alias => lc($_) ) for @bound;
    
    Clownfish::CFC::Binding::Perl::Class->register($binding);
}

1;
