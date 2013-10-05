package Selenium::TestUtil;
use strict;
use warnings;
use Try::Tiny;
use Carp;
use Socket;
use Fcntl;

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

When you use Selenium::TestUtil, you can quickly import some values into local
variables in your script.

  my ($driver, $app);
  use Selenium::TestUtil app_url => \$app, driver => \$driver;
  
  $driver->get("http://$app/");


=cut

sub import {
	my ($class, %args)= @_;
	require Test::More;
	
	# Can't run these tests unless we have the selenium webdriver module
	my $have_selenium= try { require Selenium::Remote::Driver; 1; };
	Test::More::plan(skip_all => "Can't run selenium tests without Selenium::Remote::Driver")
		unless $have_selenium;

	# Don't want to run them unless user specifies the name of a host running
	# a selenium server
	Test::More::plan(skip_all => "No SELENIUM_HOST specified; try script/prove-with-testserver")
		unless defined $class->selenium_host;

	# Scalar-refs can be passed to imort as a sugary way to grab these values.
	for (qw: driver app_url :) {
		if (defined $args{$_}) {
			my $ref= delete $args{$_};
			ref $ref eq 'SCALAR' or croak "Required scalar ref for '$_'";
			$$ref= $class->$_;
		}
	}
	
	croak "Unknown argument $_" for keys %args;
}

=head1 METHODS

=head2 driver

This is the driver object we use to communicate with the browser running on the
Selenium server

=cut

my $driver;
sub driver {
	$driver ||= Selenium::Remote::Driver->new(
		remote_server_addr => $ENV{SELENIUM_HOST},
		port => $ENV{SELENIUM_PORT} || 4444,
		browser_name => $ENV{SELENIUM_BROWSER} || 'firefox',
	);
}

=head2 app_url

This is the URL which selenium server's browser should request in order to
reach our locally-running test_app.

=cut

sub app_url {
	my $class= shift;
	$class->test_app_host.':'.$class->test_app_port;
}

=head2 find_address_facing_selenium

Returns an IP address in numeric notation which is our best guess of what IP
address selenium server should use to connect back to our app.  Returns undef
if we can't tell.

selenium_host and selenium_port must be set before calling this, and it will
attempt to connect to the that server.

=cut

sub find_address_facing_selenium {
	my $class= shift;
	socket(my $s, Socket::PF_INET, Socket::SOCK_STREAM, 0)
		or return undef;
	# Set non-blocking mode
	fcntl($s, Fcntl::F_SETFL, fcntl($s, Fcntl::F_GETFL, 0) | Fcntl::O_NONBLOCK);
	# Start a connection, but don't bother waiting for it.
	connect($s, Socket::pack_sockaddr_in(1, Socket::inet_aton($class->selenium_host)));
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
	my $class= shift;
	socket(my $s, Socket::PF_INET, Socket::SOCK_STREAM, 0)
		or return undef;
	# find out whether we can bind to TEST_APP_HOST at all.
	return (Socket::unpack_sockaddr_in(getsockname($s)))[0]
		if $class->test_app_host
			and bind($s, Socket::pack_sockaddr_in(0, inet_aton($class->test_app_host)));
	# Fall back to binding to wildcard
	return (Socket::unpack_sockaddr_in(getsockname($s)))[0]
		if bind($s, Socket::pack_sockaddr_in(0, Socket::INADDR_ANY));
	# else we have no idea
	return undef;
}


1;