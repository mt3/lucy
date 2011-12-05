#!/usr/bin/perl

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

use Getopt::Std;
use UnicodeTable;

my $out_filename = '../../core/Lucy/Analysis/WordBreak.tab';

my %wb_map = (
    CR           => 0,
    LF           => 0,
    Newline      => 0,
    ALetter      => 2,
    Numeric      => 3,
    Katakana     => 4,
    ExtendNumLet => 5,
    Extend       => 6,
    Format       => 6,
    MidNumLet    => 7,
    MidLetter    => 8,
    MidNum       => 9,
);

my %opts;
if ( !getopts( 'c', \%opts ) || @ARGV != 1 ) {
    print STDERR (<<'EOF');
Usage: gen_word_break_tables.pl [-c] UNICODE_SRC_DIR

UNICODE_SRC_DIR should point to a directory containing the files
WordBreakProperty.txt and DerivedCoreProperties.txt from
http://www.unicode.org/Public/6.0.0/ucd/

Options:
-c  Show total table size for different shift values
EOF
    exit;
}

my $src_dir = $ARGV[0];

my $wb = UnicodeTable->read(
    filename => "$src_dir/WordBreakProperty.txt",
    type     => 'Enumerated',
    map      => \%wb_map,
);
my $alpha = UnicodeTable->read(
    filename => "$src_dir/DerivedCoreProperties.txt",
    type     => 'Boolean',
    map      => { Alphabetic => 1 },
);

# Set characters in Alphabetic but not in Word_Break to WB_ASingle = 1
for ( my $i = 0; $i < 0x30000; ++$i ) {
    if ( !$wb->lookup($i) && $alpha->lookup($i) ) {
        $wb->set( $i, 1 );
    }
}

if ( $opts{c} ) {
    $wb->calc_sizes( [ 2, 5 ], [ 3, 9 ] );
}
else {
    # These give the smallest size
    my $shift1 = 6;
    my $shift2 = 3;

    my $table3 = $wb->compress($shift2);
    my $table2 = $table3->index->compress($shift1);
    my $table1 = $table2->index;
    $table3->index($table2);

    for ( my $i = 0; $i < 0x110000; ++$i ) {
        my $v1 = $wb->lookup($i);
        my $v2 = $table3->lookup($i);
        die("test for code point $i failed, want $v1, got $v2")
            if $v1 != $v2;
    }

    open( my $out_file, '>', $out_filename )
        or die("$out_filename: $!\n");

    print $out_file (<DATA>);

    $table1->dump( $out_file, 'wb_table1' );
    print $out_file ("\n");
    $table2->dump( $out_file, 'wb_table2' );
    print $out_file ("\n");
    $table3->dump( $out_file, 'wb_table3' );

    close($out_file);
}

__DATA__
/*

This file is generated with devel/bin/gen_word_break_tables.pl. DO NOT EDIT!
The contents of this file are derived from the Unicode Character Database,
version 6.0.0, available from http://www.unicode.org/Public/6.0.0/ucd/.
The Unicode copyright and permission notice follows.

Copyright (c) 1991-2011 Unicode, Inc. All rights reserved. Distributed under
the Terms of Use in http://www.unicode.org/copyright.html.

Permission is hereby granted, free of charge, to any person obtaining a copy of
the Unicode data files and any associated documentation (the "Data Files") or
Unicode software and any associated documentation (the "Software") to deal in
the Data Files or Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, and/or sell copies
of the Data Files or Software, and to permit persons to whom the Data Files or
Software are furnished to do so, provided that (a) the above copyright
notice(s) and this permission notice appear with all copies of the Data Files
or Software, (b) both the above copyright notice(s) and this permission notice
appear in associated documentation, and (c) there is clear notice in each
modified Data File or in the Software as well as in the documentation
associated with the Data File(s) or Software that the data or software has been
modified.

THE DATA FILES AND SOFTWARE ARE PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT OF THIRD
PARTY RIGHTS. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR HOLDERS INCLUDED IN
THIS NOTICE BE LIABLE FOR ANY CLAIM, OR ANY SPECIAL INDIRECT OR CONSEQUENTIAL
DAMAGES, OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING
OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THE DATA FILES OR
SOFTWARE.

Except as contained in this notice, the name of a copyright holder shall not be
used in advertising or otherwise to promote the sale, use or other dealings in
these Data Files or Software without prior written authorization of the
copyright holder.

*/

