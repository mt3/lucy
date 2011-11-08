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

use 5.010;
use strict;
use warnings;
use Getopt::Long qw( GetOptions );

my $usage
    = qq|$0 --version=X.Y.Z-rcN --apache-id=APACHE_ID --name="FULL NAME"\n|;

my ( $full_rc_version, $apache_id, $name );
GetOptions(
    'version=s'   => \$full_rc_version,
    'apache-id=s' => \$apache_id,
    'name=s'      => \$name,
);
$full_rc_version or die $usage;
$apache_id       or die $usage;
$name            or die $usage;
$apache_id =~ /^\w+$/ or die $usage;
$full_rc_version =~ m/^(\d+)\.(\d+)\.(\d+)-rc(\d+)$/ or die $usage;
my ( $major, $minor, $micro, $rc ) = ( $1, $2, $3, $4 );
my $x_y_z_version = sprintf( "%d.%d.%d", $major, $minor, $micro );

say qq|#######################################################################|;
say qq|# Commands needed to execute ReleaseGuide for Apache Lucy $x_y_z_version RC $rc|;
say qq|#######################################################################\n|;

say qq|# If your code signing key is not already available from pgp.mit.edu|;
say qq|# and <http://www.apache.org/dist/incubator/lucy/KEYS>, publish it.|;
say qq|[...]\n|;

if ( $rc < 2 ) {
    say qq|# Since this is the first RC, run update_version.|;
    say qq|./devel/bin/update_version $x_y_z_version\n|;
    say qq|# Update the the CHANGES file and associate release $x_y_z_version with today's date.|;
    say qq|[...]\n|;
    say qq|# Commit version bump and CHANGES.|;
    say qq|svn commit -m "Updating CHANGES and version number for release $x_y_z_version."\n|;
}

if ( $micro == 0 && $rc < 2) {
    say qq|# Since this is the first release in a series (i.e. X.Y.0), create a branch.|;
    say qq|svn copy https://svn.apache.org/repos/asf/incubator/lucy/trunk |
        . qq|https://svn.apache.org/repos/asf/incubator/lucy/branches/$major.$minor |
        . qq|-m "Branching for $x_y_z_version release"\n|;
}

say qq|# Create a tag for the release candidate.|;
say
    qq|svn copy https://svn.apache.org/repos/asf/incubator/lucy/branches/$major.$minor |
    . qq|https://svn.apache.org/repos/asf/incubator/lucy/tags/apache-lucy-incubating-$full_rc_version |
    . qq|-m "Tagging release candidate $rc for $x_y_z_version."\n|;


say qq|# Export a pristine copy of the source from the release candidate tag.|;
say qq|svn export https://svn.apache.org/repos/asf/incubator/lucy/tags/apache-lucy-incubating-$full_rc_version |
 . qq|apache-lucy-incubating-$x_y_z_version\n|;

say qq|# Tar and gzip the export.|;
say qq|tar -czf apache-lucy-incubating-$x_y_z_version.tar.gz apache-lucy-incubating-$x_y_z_version\n|;

say qq|# Generate checksums.|;
say qq|perl -MDigest -e '\$d = Digest->new("MD5"); open \$fh, |
    . qq|"<apache-lucy-incubating-$x_y_z_version.tar.gz" or die; |
    . qq|\$d->addfile(\$fh); print \$d->hexdigest; |
    . qq|print "  apache-lucy-incubating-$x_y_z_version.tar.gz\\n"' > |
    . qq| apache-lucy-incubating-0.2.2.tar.gz.md5|;
say qq|perl -MDigest -e '\$d = Digest->new("SHA-512"); open \$fh, |
    . qq|"<apache-lucy-incubating-$x_y_z_version.tar.gz" or die; |
    . qq|\$d->addfile(\$fh); print \$d->hexdigest; |
    . qq|print "  apache-lucy-incubating-$x_y_z_version.tar.gz\\n"' > |
    . qq| apache-lucy-incubating-0.2.2.tar.gz.sha\n|;

say qq|# Sign the release.|;
say qq|gpg --armor --output apache-lucy-incubating-$x_y_z_version.tar.gz.asc |
 . qq|--detach-sig apache-lucy-incubating-$x_y_z_version.tar.gz\n|;

say qq|# Break out CHANGES as a separate file.|;
say qq|cp -p apache-lucy-incubating-$x_y_z_version/CHANGES CHANGES-$x_y_z_version.txt\n|;

say qq|# Copy files to people.apache.org.|;
say qq|ssh $apache_id\@people.apache.org|;
say qq|mkdir public_html/apache-lucy-incubating-$full_rc_version|;
say qq|exit|;
say qq|scp -p apache-lucy-incubating-$x_y_z_version.tar.gz* |
 . qq|people.apache.org:~/public_html/apache-lucy-incubating-$full_rc_version|;
say qq|scp -p CHANGES-$x_y_z_version.txt |
 . qq|people.apache.org:~/public_html/apache-lucy-incubating-$full_rc_version\n|;

say qq|# Modify permissions.|;
say qq|ssh $apache_id\@people.apache.org|;
say qq|cd public_html/apache-lucy-incubating-$full_rc_version/|;
say qq|find . -type f -exec chmod 664 {} \\;|;
say qq|find . -type d -exec chmod 775 {} \\;|;
say qq|chgrp -R incubator *\n|;

say qq|# Perform whatever QC seems prudent on the tarball, installing it|;
say qq|# on test systems, etc.|;
say qq|[...]\n|;

say qq|#######################################################################|;
say qq|# Voting|;
say qq|#######################################################################\n|;

say qq|# Call a release vote on the dev list, referring to the artifacts|;
say qq|# made public in the previous step and using the first of the two|;
say qq|# boilerplate emails below.|;
say qq|[...]\n|;

say qq|# Once the PPMC vote has passed, call a release vote on the Incubator|;
say qq|# general@ list, using the second of the boilerplate emails below.|;
say qq|# Each release requires at least 3 Incubator PMC votes to pass; even |;
say qq|# if we get those three +1 votes from our Mentors during the PPMC|;
say qq|# vote thread on the dev list, we need to give the rest of the|;
say qq|# Incubator PMC 72 hours to vote.|;
say qq|[...]\n|;

say qq|#######################################################################|;
say qq|# After both Lucy PPMC and Incubator PMC votes have passed...|;
say qq|#######################################################################\n|;

say qq|# Tag the release.|;
say qq|svn copy https://svn.apache.org/repos/asf/incubator/lucy/tags/apache-lucy-incubating-$full_rc_version |
 . qq|https://svn.apache.org/repos/asf/incubator/lucy/tags/apache-lucy-incubating-$x_y_z_version |
 . qq|-m "Tagging release $x_y_z_version."\n|;

say qq|# Copy release artifacts to dist directory, remove RC dir.|;
say qq|ssh $apache_id\@people.apache.org|;
say qq|cd public_html/|;
say qq|cp -p apache-lucy-incubating-$full_rc_version/* /www/www.apache.org/dist/incubator/lucy/|;
say qq|rm -rf apache-lucy-incubating-$full_rc_version/\n|;

say qq|# Carefully remove the artifacts for any previous releases superseded|;
say qq|# by this one.  DO NOT overwrite any release artifact files, as that|;
say qq|# triggers the Infra team's security alarm bells.|;
say qq|cd /www/www.apache.org/dist/incubator/lucy/|;
say qq|[...]\n|;

say qq|# Update the issue tracker.|;
say qq|# While logged into JIRA, visit the following web page. (Note: this|;
say qq|# permalink may or may not work, and you may not have the necessary|;
say qq|# JIRA permissions to perform the required actions.  Please let the|;
say qq|# dev list know if you encounter problems.)  Click the "release"|;
say qq|# link for $x_y_z_version and input the date from the CHANGES file.|;
say qq|https://issues.apache.org/jira/plugins/servlet/project-config/LUCY/versions\n|;

say qq|# Once the release files are in place, update the download page|;
say qq|# of the Lucy website. The easiest way to perform this action is to|;
say qq|# use the CMS bookmarklet at https://cms.apache.org/#bookmark|;
say qq|# to access the edit screens via the CMS web interface.  Change the|;
say qq|# artifact links to point at the new version; ensure that while the|;
say qq|# primary download links point at mirrors, the signature and sums|;
say qq|# files point at apache.org.|;
say qq|[...]\n|;

say qq|# [TODO: this action cannot yet be performed by the RM, so ignore.]|; 
say qq|# Publish HTML exports of the documentation for the new release on|;
say qq|# the Lucy website.|;
say qq|[...]\n|;

say qq|# Send emails announcing the release to:|;
say qq|#|;
say qq|#     * The user list.|;
say qq|#     * The dev list.|;
say qq|#     * The Incubator general@ list.|;
say qq|#     * The announce\@a.o list.  Be sure to send from your apache.org|;
say qq|#       address|;
say qq|#|;
say qq|# Use the entry in the CHANGES file as the basis for your|;
say qq|# email, or optionally, use the boilerplate announcement text below.|;
say qq|[...]\n|;

say qq|#######################################################################|;
say qq|# Boilerplate VOTE email for lucy-dev\@incubator.a.o|;
say qq|# Suggested subject:|;
say qq|#|;
say qq|#    [VOTE] Apache Lucy (incubating) $x_y_z_version RC $rc|;
say qq|#|;
say qq|#######################################################################\n|;

say <<END_LUCY_DEV_VOTE;
Hello,

Release candidate $rc for Apache Lucy (incubating) version $x_y_z_version can
be found at:

    http://people.apache.org/~$apache_id/apache-lucy-incubating-$full_rc_version/

See the CHANGES file at the top level of the archive for information about the
content of this release.

This candidate was assembled according to the process documented at:

    http://wiki.apache.org/lucy/ReleaseGuide

It was cut from an "svn export" of the tag at:

    https://svn.apache.org/repos/asf/incubator/lucy/tags/apache-lucy-incubating-$full_rc_version

Please vote on releasing this candidate as Apache Lucy (incubating) version
$x_y_z_version.  The vote will be held open for at least the next 72 hours.

All interested parties are welcome to inspect the release candidate and
express approval or disapproval.  Votes from members of the Lucy PPMC and/or
Incubator PMC are binding; the vote passes if there are at least three binding
+1 votes and more +1 votes than -1 votes. 

Should this vote pass, a ratifying vote of the Incubator PMC will be held on
general\@incubator.a.o.  Any votes cast by Incubator PMC members here will be
carried forward into that vote.

For suggestions as to how to evaluate Apache Lucy release candidates, and for
information on ASF voting procedures, see:

    http://wiki.apache.org/lucy/ReleaseVerification
    http://wiki.apache.org/lucy/ReleasePrep
    http://www.apache.org/foundation/voting.html

[ ] +1 Release RC $rc as Apache Lucy (incubating) version $x_y_z_version.
[ ] +0
[ ] -1 Do not release RC $rc as Apache Lucy (incubating) version $x_y_z_version because...

Thanks!
END_LUCY_DEV_VOTE

say qq|#######################################################################|;
say qq|# Boilerplate VOTE email for general\@incubator.a.o|;
say qq|# Suggested subject:|;
say qq|#|;
say qq|#    [VOTE] Apache Lucy (incubating) $x_y_z_version RC $rc|;
say qq|#|;
say qq|# NOTE -- YOU MUST FILL IN THE LINK TO THE LUCY PPMC VOTE THREAD AND|;
say qq|#         THE VOTE TALLIES FOR INCUBATOR PMC MEMBERS!!!|;
say qq|#######################################################################\n|;

say <<END_GENERAL_AT_INCUBATOR_VOTE;
Hello,

Release candidate $rc for Apache Lucy (incubating) version $x_y_z_version can
be found at:

    http://people.apache.org/~$apache_id/apache-lucy-incubating-$full_rc_version/

See the CHANGES file at the top level of the archive for information about the
content of this release.

This candidate was assembled according to the process documented at:

    http://wiki.apache.org/lucy/ReleaseGuide

It was cut from an "svn export" of the tag at:

    https://svn.apache.org/repos/asf/incubator/lucy/tags/apache-lucy-incubating-$full_rc_version

For suggestions as to how to evaluate Apache Lucy release candidates, and for
information on ASF voting procedures, see:

    http://wiki.apache.org/lucy/ReleaseVerification
    http://wiki.apache.org/lucy/ReleasePrep
    http://www.apache.org/foundation/voting.html

Apache Lucy PPMC vote thread:

    ###LINK_TO_LUCY_PPMC_VOTE_THREAD###

    ###PPMC_VOTE_TALLY###

    * indicates Lucy PPMC member
    + indicates Incubator PMC member

Please vote on releasing this candidate as Apache Lucy (incubating) version
$x_y_z_version.  The vote will be held open for at least the next 72 hours.

[ ] +1 Release RC $rc as Apache Lucy (incubating) version $x_y_z_version.
[ ] +0
[ ] -1 Do not release RC $rc as Apache Lucy (incubating) version $x_y_z_version because...

Thanks!
END_GENERAL_AT_INCUBATOR_VOTE

say qq|#######################################################################|;
say qq|# Boilerplate ANNOUNCE email|;
say qq|# Suggested subject:|;
say qq|#|;
say qq|#    [ANNOUNCE] Apache Lucy (incubating) $x_y_z_version released|;
say qq|#|;
say qq|#######################################################################\n|;

say <<END_ANNOUNCE_EMAIL;
Greetings,

The Apache Lucy team is pleased to announce the release of version $x_y_z_version
from the Apache Incubator!

Apache Lucy is full-text search engine library written in C and targeted at
dynamic languages.  For a list of issues resolved in this version, please see
the release notes:

  http://www.apache.org/dist/incubator/lucy/CHANGES-$x_y_z_version.txt

The most recent release can be obtained from our download page:

  http://incubator.apache.org/lucy/download.html

For general information on Apache Lucy, please visit the project website:

  http://incubator.apache.org/lucy/

Disclaimer:

  Apache Lucy is an effort undergoing incubation at The Apache Software
  Foundation (ASF), sponsored by the Apache Incubator. Incubation is required
  of all newly accepted projects until a further review indicates that the 
  infrastructure, communications, and decision making process have stabilized
  in a manner consistent with other successful ASF projects.  While incubation
  status is not necessarily a reflection of the completeness or stability of
  the code, it does indicate that the project has yet to be fully endorsed by
  the ASF.

Regards, 

$name, on behalf of the Apache Lucy development team and community

END_ANNOUNCE_EMAIL

say qq|#######################################################################|;

