package RA::InfoSite;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;
use RapidApp 0.99015;

use Catalyst;

with qw(
  Catalyst::Plugin::RapidApp::RapidDbic
  Catalyst::Plugin::RapidApp::AuthCore
  Catalyst::Plugin::RapidApp::NavCore
);

our $VERSION = '0.01';
our $TITLE = "RA::InfoSite v" . $VERSION;

__PACKAGE__->config(
  name => 'RA::InfoSite',
  
  'Model::RapidApp' => {
    root_template_prefix => 'public/section/',
    root_template => 'public/section/home'
  },
  
  'Plugin::RapidApp::RapidDbic' => {
    title => $TITLE,
    nav_title => 'www.rapidapp.info',
    dashboard_url => '/',
    template_navtree_regex => '.',
    dbic_models => [
      'RapidApp::CoreSchema'
    ],
    configs => {
      'RapidApp::CoreSchema' => {
        grid_params => {
          '*defaults' => {
            updatable_colspec => ['*'],
            creatable_colspec => ['*'],
            destroyable_relspec => ['*'],
            #cache_total_count => 0,
            #plugins => ['grid-edit-advanced-config']
          },
          Role => {
            no_page => 1,
            persist_immediately => {
              create => \0,
              update => \0,
              destroy	=> \0
            },
            extra_extconfig => { use_add_form => \0 }
          }
        }
      },
    }
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
