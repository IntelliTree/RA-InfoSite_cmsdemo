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

my $tpl_regex = '^public\/section\/';

__PACKAGE__->config(
  name => 'RA::InfoSite',
  
  'Model::RapidApp' => {
    root_template_prefix  => 'public/section/',
    root_template         => 'public/section/home'
  },
  
  'Plugin::RapidApp::TabGui' => {
    title => $TITLE,
    nav_title => 'www.rapidapp.info',
    dashboard_url => '/',
    #template_navtree_regex => $tpl_regex,
  },
  
  'Controller::RapidApp::Template' => {
    default_template_extension => 'html',
    access_params => {
      writable_regex      => $tpl_regex,
      creatable_regex     => $tpl_regex,
      deletable_regex     => $tpl_regex,
      external_tpl_regex  => '^public\/',
    }
  },
 
);

# Start the application
__PACKAGE__->setup();

1;
