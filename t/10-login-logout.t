#! /usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Try::Tiny;
use lib (-d 't'? 't/lib' : 'lib');
use Selenium::TestUtil qw( &&skipcheck driver $app KEYS );


driver->delete_all_cookies();
driver->set_implicit_wait_timeout(6000);  # 6 sec.  some pages load slowly...

# Load the front page, find the login link, and click it.

driver->get("http://$app/");
ok( (my $login= driver->find_element(q{//a[text()='Login']})), 'has login button' );
ok( driver->find_element(q{//div[contains(.,"not logged in")]}), 'not-logged-in message' );
like( driver->get_title, qr/RapidApp/, 'root page title' );

defined $login
	or BAIL_OUT("No login button");

$login->click();

# Verify components of the login page

ok( (my $login_box= driver->find_element('login_box', 'class')), 'login page login box' );
like( driver->get_title, qr/login/i, 'login page title' );
ok( (my $user_blank= driver->find_element(q{//input[@name='username']})), 'has username blank' );
ok( (my $pass_blank= driver->find_element(q{//input[@name='password']})), 'has pass blank' );
is( $pass_blank->get_attribute('type'), 'password', 'is a password type field' );
ok( (my $login_button= driver->find_element(q{//input[@type='submit']})), 'has login button' );
like( $login_button->get_value, qr/login/i, 'login correctly labeled' );

$user_blank && $pass_blank && $login_button
	or BAIL_OUT("Missing login page components");

# Try logging in with incorrect password
# Ensure we come back to the login page, with an error message

$user_blank->click();
driver->send_keys_to_active_element("admin", KEYS->{tab}, "wrong", KEYS->{enter});

ok( ($login_box= driver->find_element(q{//div[@class='login_box']})), 'login page login box' );
ok( driver->find_element(q{//div[contains(.,"Authentication failure")]}), 'says login failed' );

ok( ($user_blank= driver->find_element(q{//input[@name='username']})), 'username blank' )
	or BAIL_OUT("Lost the username blank");

# Try logging in with correct username/password

$user_blank->click();
driver->send_keys_to_active_element("admin", KEYS->{tab}, "pass", KEYS->{enter});

# Ensure we made it to the admin UI

ok( (my $logout= driver->find_element(q{//a[text()='Logout']})), 'has logout button' );
like( driver->get_title, qr/RA::InfoSite/, 'admin page title' );
defined $logout or BAIL_OUT("No logout button...");

# Now log back out, and ensure we make it back to the front page

$logout->click();

ok( driver->find_element(q{//div[contains(.,"not logged in")]}), 'not-logged-in message' );
like( driver->get_title, qr/RapidApp/, 'root page title' );

done_testing;