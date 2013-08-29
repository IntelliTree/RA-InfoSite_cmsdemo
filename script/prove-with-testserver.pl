#! /usr/bin/env perl

use strict;
use warnings;
use Try::Tiny;
use Socket;
use POSIX ":sys_wait_h";

die "No SELENIUM_HOST specified\n"
	unless defined $ENV{SELENIUM_HOST};

# SELENIUM_HOST can contain a port, but we want to simplify the
# rest of the scripts, so split that into a separate var
($ENV{SELENIUM_HOST} =~ /^([^:]+)(:(\d+))?$/)
	or die "Invalid SELENIUM_HOST setting: '$ENV{SELENIUM_HOST}'";
if ($3) {
	$ENV{SELENIUM_PORT}= $3;
	$ENV{SELENIUM_HOST}= $1;
}

$ENV{TEST_APP_HOST} ||= guess_network_address(from => $ENV{SELENIUM_HOST})
	or die "Can't guess value for TEST_APP_HOST. Please set manually "
		."to the IP addr SELENIUM_HOST should use to connect back to us.\n";
$ENV{TEST_APP_PORT} ||= find_free_port()
	or die "Can't find a free port to run the app on.\n";
$ENV{TEST_APP_STARTUP_TIMEOUT} ||= 10;

# Start an instance of the webapp
warn "Starting webapp on port $ENV{TEST_APP_PORT}\n";

defined (my $server_pid= fork()) or die "fork(): $!";

exec_server_or_exit() if 0 == $server_pid;

my $result= 2;
try {
	if (!wait_for_server_ready()) {
		warn "Not running 'prove'\n";
	}
	else {
		$result= system('prove', @ARGV);
		if ($result < 0) {
			warn "Can't exec 'prove': $!\n";
			$result= 2;
		}
	}
} catch {
	warn "exception: $_\n";
};
if (defined $server_pid) {
	warn "Terminating webapp\n";
	kill TERM => $server_pid;
	waitpid($server_pid, 0);
}
exit($result);

sub exec_server_or_exit {
	use FindBin;
	my $script= "$FindBin::Bin/../script/ra_infosite_server.pl";
	close STDIN;
	exec $script, '-p', $ENV{TEST_APP_PORT}
		or warn "exec($script): $!\n";
	# exec failed, but we still want exec() semantics, if possible.
	# i.e. no destructors of objects that might use handles shared with the parent.
	exec 'false' or warn "exec(false): $!\n";
	exit(1);
}

sub guess_network_address {
	'172.20.0.41'
}

sub find_free_port {
	4001;
}

sub wait_for_server_ready {
	socket(my $socket, Socket::PF_INET, Socket::SOCK_STREAM, 0)
		or die "socket(): $!";
	my $deadline= time + $ENV{TEST_APP_STARTUP_TIMEOUT};
	my $result= '';
	while (1) {
		if (connect($socket, pack_sockaddr_in($ENV{TEST_APP_PORT}, inet_aton('localhost')))) {
			$result= 1;
			last;
		}
		if (waitpid($server_pid, WNOHANG) == $server_pid) {
			warn "Server terminated during startup\n";
			$server_pid= undef;
			last;
		}
		if (time > $deadline) {
			warn "Server not ready after $ENV{TEST_APP_STARTUP_TIMEOUT} seconds. "
				."You might need to adjust TEST_APP_STARTUP_TIMEOUT\n";
			last;
		}
		select(undef, undef, undef, 0.2); # sleep 0.2;
	}
	close $socket;
	return $result;
}
