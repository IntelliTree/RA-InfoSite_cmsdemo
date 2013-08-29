#! perl

use strict;
use warnings;
use Test::More;
use Try::Tiny;
use Socket;

BEGIN {
	# Can't run these tests unless we have the selenium webdriver module
	my $have_selenium= try { require Selenium::Remote::Driver; 1; };
	plan skip_all => "Can't run selenium tests without Selenium::Remote::Driver"
		unless $have_selenium;

	# Don't want to run them unless user specifies the name of a host running
	# a selenium server
	plan skip_all => "No SELENIUM_HOST specified; try script/prove-with-testserver.pl"
		unless defined $ENV{SELENIUM_HOST};
}

use Selenium::Remote::WDKeys;

my $driver= Selenium::Remote::Driver->new(
	remote_server_addr => $ENV{SELENIUM_HOST},
	port => $ENV{SELENIUM_PORT} || 4444,
	browser_name => $ENV{SELENIUM_BROWSER} || 'firefox',
);

my $app= "$ENV{TEST_APP_HOST}:$ENV{TEST_APP_PORT}";
$driver->get("http://$app/");
like( $driver->get_title, qr/RapidApp/, 'page title' );

done_testing;