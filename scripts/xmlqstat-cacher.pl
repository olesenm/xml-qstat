#!/usr/bin/perl -w
# avoid starter method here - otherwise we cannot kill the daemon
use strict;
use POSIX qw();
use Getopt::Std qw( getopts );
import Sge;

###############################################################################
# CUSTOMIZE THESE SETTINGS TO MATCH YOUR REQUIREMENTS:
#
my %config = (
    ## Decide where your cached XML files will be stored
    ## or override on the command-line
    ## Set to an empty string to suppress the query and the output.
    dir     => "/opt/grid/default/site/xml-qstat/web-app/cache",
    qstatf  => "qstatf.xml",
    qstat   => "",
    qhost   => "",
    qlic    => "",
    delay   => 30,
    timeout => 10,
);

#
# END OF CUSTOMIZE SETTINGS
###############################################################################

# -----------------------------------------------------------------------------
# Copyright (c) 2006-2007 Chris Dagdigian (dag@sonsorol.org)
# Copyright (c) 2009-2011 Mark Olesen
#
# License
#     This file is part of xml-qstat.
#
#     xml-qstat is free software: you can redistribute it and/or modify it under
#     the terms of the GNU Affero General Public License as published by the
#     Free Software Foundation, either version 3 of the License,
#     or (at your option) any later version.
#
#     xml-qstat is distributed in the hope that it will be useful, but
#     WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
#     or FITNESS FOR A PARTICULAR PURPOSE.
#     See the GNU Affero General Public License for more details.
#
#     You should have received a copy of the GNU Affero General Public License
#     along with xml-qstat. If not, see <http://www.gnu.org/licenses/>.
#
# Script
#     xmlqstat-cacher.sh
#
# Description
#     Cache GridEngine information in xml format.
#
# -----------------------------------------------------------------------------
( my $Script = $0 ) =~ s{^.*/}{};

# --------------------------------------------------------------------------
sub usage {
    $! = 0;    # clean exit
    warn "@_\n" if @_;
    die <<"USAGE";
usage: $Script [OPTION] [PARAM]
  Cache GridEngine information in xml format.

options:
  -d      daemonize

  -h      help

  -k      kill running daemon

  -w      wake-up daemon from sleep

params:
  delay=N
            waiting period in seconds between queries in daemon mode
            (a delay of 0 is interpreted as 30 seconds)

  dir=DIR
            base directory prefix for output files (qhost, qstat, ...)

  qhost=FILE
            save 'qhost' query (as per qlicserver) to FILE
            (default: $config{qhost})

  qlic=FILE
            create dummy qlicserver.xml output to FILE
            (default: $config{qlic})

  qstat=FILE
            save 'qstat' query (as per qlicserver) to FILE
            (default: $config{qstat})

  qstatf=FILE
            save 'qstat -f' query to FILE
            (default: $config{qstatf})

  timeout=N
            command timeout in seconds (default: 10 seconds)


Use the qhost,qstat,qlic queries if you do not have the qlicserver running
but wish to use the corresponding XSLT transformations.

USAGE
}

# --------------------------------------------------------------------------
my %opt;
getopts( "hdkw", \%opt );    # tolerate faults on unknown options
$opt{h} and usage();

sub kill_daemon {
    my $signal = shift || 9;
    my @list =
      grep { $_ != $$ }
      map  { /^\s*(\d+)\s*$/ } qx{ps -C $Script -o pid= 2>/dev/null};
    kill $signal => @list if @list;
}

# ---------------------------------------------------------------------------
# '-k'
# terminate processes
# ---------------------------------------------------------------------------
if ( $opt{k} ) {
    kill_daemon 15;    # TERM
    exit 0;
}

# ---------------------------------------------------------------------------
# '-w'
# wakeup daemon
# ---------------------------------------------------------------------------
if ( $opt{w} ) {
    kill_daemon 10;    # USR1
    exit 0;
}

# extract command-line parameters of the form param=value
# we can only overwrite the default config
for (@ARGV) {
    if ( my ( $k, $v ) = /^([A-Za-z]\w*)=(.+)$/ ) {
        if ( exists $config{$k} ) {
            $config{$k} = $v;
        }
    }
}

# ---------------------------------------------------------------------------
# standard query, with optional '-d' (daemonize)
# ---------------------------------------------------------------------------
my $daemon = $opt{d};

if ($daemon) {    # daemonize

    # the delay between loops
    my $delay = $config{delay};
    $daemon = ( $delay and $delay =~ /^\d+$/ ) ? $delay : 30;

    # terminate old processes
    kill_daemon 15;    # TERM

    my $pid = fork;
    exit if $pid;      # let parent exit
    defined $pid or die "Couldn't fork: $!";

    # create a new process group
    POSIX::setsid() or die "Can't start a new session: $!";

    # Trap fatal signals, setting flag to exit gracefully
    $SIG{INT} = $SIG{TERM} = $SIG{HUP} = sub { undef $daemon };
    $SIG{PIPE} = "IGNORE";
    $SIG{USR1} = sub { sleep 0; };    # allow wake-up on demand
}

# setup before query
# adjust timeout - the license server is the Achilles heel
if ( exists $config{timeout} ) {
    Shell->timeout( $config{timeout} );
}

# one query must be defined
usage "ERROR: define at least one of 'qhost', 'qstat' or 'qstatf'\n"
  if not grep { $config{$_} } qw( qhost qstat qstatf );

#
# resolve output file names relative to output 'dir'
# stdout (-) and absolute names are left untouched,
# as are names in the current working directory (starting with "./")
#
if ( length $config{dir} ) {
    my $dir = $config{dir};

    unless ( -d $dir ) {
        ## only create the cache directory when the parent exists
        if ( ( my $parent = $dir ) =~ s{/[^/]+$}{} ) {
            if ( -d $parent ) {
                mkdir $dir;
            }
            else {
                warn "no parent directory for $dir\n";
            }
        }
        else {
            mkdir $dir;
        }
    }

    for (qw( qhost qstat qstatf qlic )) {
        my $file = $config{$_};
        if ( length $file and $file !~ m{^\.?/} and $file ne "-" ) {
            $config{$_} = "$dir/$file";    ## resolved form
        }
    }
}

# Query Grid Engine for XML status data
if ( $config{qlic} ) {
    Sge->writeCache(
        $config{qlic},
        (
                qq{<?xml version="1.0"?>\n}
              . qq{<qlicserver>dummy file generated by '$Script'</qlicserver>\n}
        )
    );
}

do {
    Sge->qstatfCacher( $config{qstatf} );
    Sge->qstatCacher( $config{qstat} );
    Sge->qhostCacher( $config{qhost} );
    sleep( $daemon || 0 );
} while $daemon;

exit 0;

# --------------------------------------------------------------------------
# somewhat like the qx// command with a timeout mechanism,
# but for safety it only handles a list form (no shell escapes)
#

package Shell;
our ( $timeout, $report );

BEGIN {
    $timeout = 10;
}

#
# assign new value for reporting the timeout
#
sub report {
    my ( $caller, $value ) = @_;
    $report = $value;
}

#
# assign new timeout
#
sub timeout {
    my ( $caller, $value ) = @_;
    $timeout = ( $value and $value =~ /^\d+$/ ) ? $value : 10;
}

sub cmd {
    my ( $caller, @command ) = @_;
    my ( @lines, $pid, $redirected );
    local ( *OLDERR, *PIPE );

    # kill off truant child: this works well for unthreaded processes,
    # but threaded processes are still an issue
    local $SIG{__DIE__} = sub { kill TERM => $pid if $pid; };

    eval {
        local $SIG{ALRM} = sub { die "TIMEOUT\n" };         # NB: '\n' required
        alarm $timeout if $timeout;
        @command or die "$caller: Shell->cmd with an undefined query\n";

        if ( open OLDERR, ">&", \*STDERR ) {
            $redirected++;
            open STDERR, ">/dev/null";
        }

        $pid = open PIPE, '-|', @command;    # open without shell (forked)
        if ($pid) {
            @lines = <PIPE>;
        }

        die "(EE) ", @lines if $?;
        alarm 0;
    };

    # restore stderr
    open STDERR, ">&OLDERR" if $redirected;

    if ($@) {
        if ( $@ =~ /^TIMEOUT/ ) {
            warn "(WW) TIMEOUT after $timeout seconds on '@command'\n" if $report;
            return undef;
        }
        else {
            die $@;    # propagate unexpected errors
        }
    }

    wantarray ? @lines : join '' => @lines;
}

1;

# --------------------------------------------------------------------------
package Sge;
use vars qw( $bin );

BEGIN {
    $ENV{SGE_SINGLE_LINE} = 1;    # do not break up long lines with backslashes

    $bin = $ENV{SGE_BINARY_PATH} || '';

    if ( -d ( $ENV{SGE_ROOT} || '' ) ) {
        my $arch = $ENV{SGE_ARCH}
          || qx{$ENV{SGE_ROOT}/util/arch}
          || 'NONE';

        chomp $arch;

        -d $bin or $bin = "$ENV{SGE_ROOT}/bin/$arch";
    }

    for ($bin) {
        if ( -d $_ ) {
            s{/*$}{/};
        }
        else {
            $_ = '';
        }
    }

}

# relay command to Shell
sub bin {
    my $caller = shift;
    my $cmd    = $bin . (shift);

    return Shell->cmd( $cmd, @_ );
}

# write readonly cache file,
# using temp file with rename to avoid race conditions
sub writeCache {
    my $caller    = shift;
    my $cacheFile = shift;
    @_ or return;

    my $tmpFile = $cacheFile;
    if ( $cacheFile ne "-" ) {    # catch "-" STDOUT alias
        $tmpFile .= ".TMP";
        unlink $tmpFile;
    }
    local *FILE;
    open FILE, ">$tmpFile" or return;

    for (@_) {
        print FILE $_;
    }

    close FILE;                   # explicitly close before rename
    if ( $tmpFile ne $cacheFile ) {
        chmod 0444      => $tmpFile;      # output cache is readonly
        rename $tmpFile => $cacheFile;    # atomic
    }
}

# --------------------------------------------------------------------------

#
# get and cache 'qstat -f' output
#
sub qstatfCacher {
    my $caller    = shift;
    my $cacheFile = shift or return;

    my @args =
      ( qw( -u * -xml -r -f -explain aAcE ), -F => "load_avg,num_proc" );

    my $lines = Sge->bin( qstat => @args )
      or return;

    # document the request without affecting the xml structure:
    # inject the query date and arguments as processing instructions
    # newer perl can use \K for a variable-length look behind
    my $date = POSIX::strftime( "%FT%T", localtime );
    $lines =~ s{^(<\?xml[^\?]+\?>)}{$1\n<?qstat date="$date"?>\n<?qstat command="@args"?>};

    Sge->writeCache( $cacheFile, $lines );
}

#
# get and cache 'qstat' output (as per qlicserver)
#
sub qstatCacher {
    my $caller    = shift;
    my $cacheFile = shift or return;

    my @args = qw( -u * -xml -r -s prs );
    my $lines = Sge->bin( qstat => @args ) or return;

    # document the request without affecting the xml structure:
    # inject the query date and arguments as processing instructions
    # newer perl can use \K for a variable-length look behind
    my $date = POSIX::strftime( "%FT%T", localtime );
    $lines =~ s{^(<\?xml[^\?]+\?>)}{$1\n<?qstat date="$date"?>\n<?qstat command="@args"?>};

    Sge->writeCache( $cacheFile, $lines );
}

#
# get and cache 'qhost' output (as per qlicserver)
#
sub qhostCacher {
    my $caller    = shift;
    my $cacheFile = shift or return;

    my @args = qw( -q -j -xml );
    my $lines = Sge->bin( qhost => @args ) or return;

    # replace xmlns= with xmlns:xsd=
    # only needed for older GridEngine versions
    $lines =~ s{\s+xmlns=}{ xmlns:xsd=}s;

    # document the request without affecting the xml structure:
    # inject the query date and arguments as processing instructions
    # newer perl can use \K for a variable-length look behind
    my $date = POSIX::strftime( "%FT%T", localtime );
    $lines =~ s{^(<\?xml[^\?]+\?>)}{\n<?qhost date="$date"?>\n<?qhost command="@args"?>};

    Sge->writeCache( $cacheFile, $lines );
}

1;

# ----------------------------------------------------------------- end-of-file
