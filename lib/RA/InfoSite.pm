package RA::InfoSite;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use RapidApp 0.99014;

use Catalyst '-Debug';

with qw(
  Catalyst::Plugin::RapidApp::RapidDbic
  Catalyst::Plugin::RapidApp::AuthCore
  Catalyst::Plugin::RapidApp::NavCore
);

our $VERSION = '0.01';
our $TITLE = "RA::InfoSite v" . $VERSION;

__PACKAGE__->config(
  name => 'RA::InfoSite',
    
  'Plugin::RapidApp::RapidDbic' => {
    title => $TITLE,
    nav_title => 'www.rapidapp.info',
    dashboard_url => '/tple/dashboard.md',
    template_navtree_regex => '.',
    dbic_models => [
      'RapidApp::CoreSchema'
    ],
  },
  
  # Simple, wide-open editing of any template:
  'Controller::RapidApp::Template' => {
    access_params => {
      writable => 1,
      creatable => 1,
      deletable => 1,
      external_tpl_regex => '^public',
    }
  },
  
);

# Start the application
__PACKAGE__->setup();

1;
