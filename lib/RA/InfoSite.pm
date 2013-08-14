package RA::InfoSite;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use RapidApp 0.99015;

use Catalyst;

with (
  'Catalyst::Plugin::RapidApp::TabGui',
  'Catalyst::Plugin::RapidApp::AuthCore',
  #'Catalyst::Plugin::RapidApp::NavCore',
  #'Catalyst::Plugin::RapidApp::CoreSchemaAdmin',
);

our $VERSION = '0.01';
our $TITLE = "RA::InfoSite v" . $VERSION;

__PACKAGE__->config(
  name => 'RA::InfoSite',
  
  'Model::RapidApp' => {
    root_template_prefix => 'public/section/',
    root_template => 'public/section/home'
  },
  
  'Plugin::RapidApp::TabGui' => {
    title => $TITLE,
    nav_title => 'www.rapidapp.info',
    dashboard_url => '/',
    template_navtree_regex => '.',
  },
    
  'Plugin::RapidApp::AuthCore' => {
    login_logo_url => '/assets/rapidapp/misc/static/images/rapidapp_catalyst_logo.png',
  },
  
  # Simple, wide-open editing of any template:
  'Controller::RapidApp::Template' => {
    default_template_extension => 'html',
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
