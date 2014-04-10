class apache::params (
  $graceful_restart = false,
  $ports            = '80',
  $ssl_ports        = [],
  $default_mods_en  = [
    'alias',
    'auth_basic',
    'authn_file',
    'authz_default',
    'authz_groupfile',
    'authz_host',
    'authz_user',
    'autoindex',
    'deflate',
    'dir',
    'env',
    'expires',
    'mime',
    'negotiation',
    'reqtimeout',
    'setenvif',
    'status'
  ],
) {

  $ports_real     = any2array($ports)
  $ssl_ports_real = any2array($ssl_ports)

  $ports_file_content = template('apache/ports.erb')

  case $::operatingsystem {
    ubuntu, debian: {
      $package      = 'apache2'
      $service_name = 'apache2'
      $ports_file   = '/etc/apache2/ports.conf'
      $config_dir   = '/etc/apache2/conf.d'
      $vhost_dir    = '/etc/apache2/sites-available'
      $vhost_en_dir = '/etc/apache2/sites-enabled'
      $mod_dir      = '/etc/apache2/mods-available'
      $mod_en_dir   = '/etc/apache2/mods-enabled'
      $graceful_cmd = '/etc/init.d/apache2 graceful'
      $web_root_dir = '/var/www'
      $ensure_start = "/bin/sh -c '/etc/init.d/apache2 start || { /usr/bin/killall -9 apache2 && /bin/sleep 2 && /etc/init.d/apache2 start; }'"
      $user         = 'www-data'
      $group        = 'www-data'
    }
#    redhat, centos: {
#    }
    default: {
      fail("Unsupported platform: ${::operatingsystem}")
    }
  }
}
