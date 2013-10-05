package Selenium::TestUtil;
use strict;
use warnings;
use Try::Tiny;
use Carp;
use Socket;
use Fcntl;
use parent 'Exporter';

our (@EXPORT_OK, %EXPORT_TAGS, @EXPORT_FAIL, $app);
BEGIN {

# standard exports
@EXPORT_OK= qw( selenium_host selenium_port selenium_browser
	test_app_host test_app_port driver app_url find_address_facing_selenium
	find_port_facing_selenium $app KEYS );

# special processing for these
@EXPORT_FAIL= qw( KEYS $app );

} # BEGIN

=head1 NAME

Selenium::TestUtil - utility methods for running Selenium against a local catalyst app

=head1 DESCRIPTION

This module contains some helpful routines for running unit tests through a
Selenium server while simultaneously running a local copy of the Catalyst app
which the selenium server should be testing against.

=cut

BEGIN {
	# Parse out the selenium_port from selenium_host
	if (defined $ENV{SELENIUM_HOST} && ($ENV{SELENIUM_HOST} =~ /^([^:]+)(:(\d+))?$/)) {
		$ENV{SELENIUM_PORT}= $3;
		$ENV{SELENIUM_HOST}= $1;
	}
}

=head1 ATTRIBUTES

All these attributes directly read/write environment variables.

=head2 selenium_host ( ENV{SELENIUM_HOST} )

The hostname (or numeric address) of the selenium server.

=head2 selenium_port ( ENV{SELENIUM_PORT} )

The corresponding port where the selenium server is listening.

=head2 selenium_browser ( ENV{SELENIUM_BROWSER} )

The value passed to the default instance of Driver, to tell it which browser
to use.

=head2 test_app_host ( ENV{TEST_APP_HOST} )

The numeric address which the selenium server can connect to to get back to us.

=head2 test_app_port ( ENV{TEST_APP_PORT} )

The numeric port on the local machine where the webapp is running, which the
selenium server should run tests against.

=cut

sub selenium_host { @_ > 1? ($ENV{SELENIUM_HOST}= $_[1]) : $ENV{SELENIUM_HOST} }

sub selenium_port { (@_ > 1? ($ENV{SELENIUM_PORT}= $_[1]) : $ENV{SELENIUM_PORT})||4444 }

sub selenium_browser { @_ > 1? ($ENV{SELENIUM_BROWSER}= $_[1]) : $ENV{SELENIUM_BROWSER} }

sub test_app_host { @_ > 1? ($ENV{TEST_APP_HOST}= $_[1]) : $ENV{TEST_APP_HOST} }

sub test_app_port { @_ > 1? ($ENV{TEST_APP_PORT}= $_[1]) : $ENV{TEST_APP_PORT} }

=head1 USE

When you use Selenium::TestUtil, you can quickly get set up for a unit test with some
special import directives.

  use Selenium::TestUtil qw( &&skipcheck driver $app KEYS );
  driver->get("http://$app/");

&&skipcheck immediately *runs* the TestUtil->skipcheck function.
See L</skipcheck> for details.

driver is the method you will use most, and returns a global instance of
Selenium::Remote::Driver created with the values from the attributes of this package
(which come from environment variables).

$app is a convenient variable to use instead of 'app_url', because it can be embedded
in strings more easily than a function call.

KEYS is the symbol exported by Selenium::Remote::WDKeys, and saves you the trouble of
another 'use' line to get that symbol.

=cut

sub import {
	my ($class, @symbols)= grep { $_ ne '&&skipcheck' } @_;
	
	# If we removed anything, it means we found "&&skipcheck" in the list
	$class->skipcheck()
		if @symbols+1 < @_;
	
	$class->export_to_level(1, $class, @symbols);
}

sub export_fail {
	my ($class, @symbols)= @_;
	my @unknown;
	for my $sym (@symbols) {
		if ($sym eq 'KEYS') {
			require Selenium::Remote::WDKeys;
			Selenium::Remote::WDKeys->import('KEYS');
		} elsif ($sym eq '$app') {
			$app ||= $class->app_url;
		} else {
			push @unknown, $sym;
		}
	}
	return @unknown;
}

=head1 METHODS

=head2 have_selenium

Simply a boolean to indicate whether Selenium webdriver module is installed.

=cut

sub have_selenium {
	try { require Selenium::Remote::Driver; 1; }
}

=head2 skipcheck

Used for the top of unit tests, this function will call "plan skip_all => $reason"
for you if the environment isn't properly set up for running Selenium tests.

=cut

sub skipcheck {
	require Test::More;
	# Selenium webdriver module is required
	Test::More::plan(skip_all => "Can't run selenium tests without Selenium::Remote::Driver")
		unless __PACKAGE__->have_selenium;
	# Don't want to run them unless user specifies the name of a host running
	# a selenium server
	Test::More::plan(skip_all => "No SELENIUM_HOST specified; try script/prove-with-testserver")
		unless defined __PACKAGE__->selenium_host;
}

=head2 driver

This is the driver object we use to communicate with the browser running on the
Selenium server

=cut

my $driver;
sub driver {
	$driver ||= do {
		require Selenium::Remote::Driver;
		Selenium::Remote::Driver->new(
			remote_server_addr => __PACKAGE__->selenium_host,
			port               => __PACKAGE__->selenium_port,
			browser_name       => __PACKAGE__->selenium_browser || 'firefox',
		);
	};
}

=head2 app_url

This is the URL which selenium server's browser should request in order to
reach our locally-running test_app.

=cut

sub app_url {
	__PACKAGE__->test_app_host.':'.__PACKAGE__->test_app_port;
}

=head2 find_address_facing_selenium

Returns an IP address in numeric notation which is our best guess of what IP
address selenium server should use to connect back to our app.  Returns undef
if we can't tell.

selenium_host and selenium_port must be set before calling this, and it will
attempt to connect to the that server.

=cut

sub find_address_facing_selenium {
	socket(my $s, Socket::PF_INET, Socket::SOCK_STREAM, 0)
		or return undef;
	# Set non-blocking mode
	fcntl($s, Fcntl::F_SETFL, fcntl($s, Fcntl::F_GETFL, 0) | Fcntl::O_NONBLOCK);
	# Start a connection, but don't bother waiting for it.
	connect($s, Socket::pack_sockaddr_in(1, Socket::inet_aton(__PACKAGE__->selenium_host)));
	# See what address it bound to
	my ($port, $ip)= Socket::unpack_sockaddr_in(getsockname($s))
		or return undef;
	return $ip eq "\0\0\0\0"? undef : inet_ntoa($ip);
}

=head2 find_port_facing_selenium

Returns a port number on which the selenium server can likely connect back to
us, or undef if it can't find one.

test_app_host should be set before calling this.

=cut

sub find_port_facing_selenium {
	socket(my $s, Socket::PF_INET, Socket::SOCK_STREAM, 0)
		or return undef;
	# find out whether we can bind to TEST_APP_HOST at all.
	return (Socket::unpack_sockaddr_in(getsockname($s)))[0]
		if __PACKAGE__->test_app_host
			and bind($s, Socket::pack_sockaddr_in(0, inet_aton(__PACKAGE__->test_app_host)));
	# Fall back to binding to wildcard
	return (Socket::unpack_sockaddr_in(getsockname($s)))[0]
		if bind($s, Socket::pack_sockaddr_in(0, Socket::INADDR_ANY));
	# else we have no idea
	return undef;
}


1;