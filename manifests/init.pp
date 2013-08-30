class apache (
  $ensure = 'present',
  $autoupgrade = false
) inherits apache::params {
  #TO-DO: control allow directives http://httpd.apache.org/docs/2.2/mod/mod_authz_host.html
  #include apache::params

  #$package      = $apache::params::package
  #$config_file  = $apache::params::config_file
  #$config_dir   = $apache::params::config_dir
  #$service_name = $apache::params::service_name

  case $ensure {
    /(present)/: {
      $dir_ensure     = 'directory'
      $service_ensure = 'running'
      if $autoupgrade == true {
        $package_ensure = 'latest'
      } else {
        $package_ensure = 'present'
      }
    }
    /(absent)/: {
      $package_ensure = 'absent'
      $dir_ensure     = 'absent'
      $service_ensure = 'stopped'
    }
    default: {
      fail('ensure parameter must be present or absent')
    }
  }

  package { $package:
    ensure => $package_ensure,
  }

  $config_file_replace = true

  # TO-DO: manage main config
  # TO-DO: config-overrides

  file { $config_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    recurse => true,
    purge   => false,
    require => Package[$package],
    notify  => Service[$service_name],
  }

  #Ports file
  file { $apache::params::ports_file:
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    replace => $config_file_replace,
    content => $apache::params::ports_file_content,
    require => Package[$package],
    notify  => Service[$service_name],
  }

  #Vhosts dirs
  file { $apache::params::vhost_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    purge   => false,
    require => Package[$apache::params::package],
  }
  file { $apache::params::vhost_en_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    purge   => true,
    recurse => true,
    require => Package[$apache::params::package],
    notify  => Service[$apache::params::service_name],
  }

  #Modules
  file { $apache::params::mod_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    purge   => false,
    require => Package[$apache::params::package],
  }
  file { $apache::params::mod_en_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    recurse => true,
    purge   => true,
    require => Package[$apache::params::package],
    notify  => Service[$apache::params::service_name],
  }

  file { $apache::params::web_root_dir:
    ensure  => $dir_ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    purge   => false,
    require => Package[$package],
  }

  # TO-DO: graceful restart
  service { $service_name:
    name       => $service_name,
    ensure     => $service_ensure,
    hasstatus  => true,
    hasrestart => true,
    enable     => true,
    restart    => $apache::params::graceful_restart ? {
      true    => $apache::params::graceful_cmd,
      default => undef,
    }
  }

  @apache::module { $apache::params::default_mods_en:
    package => $apache::params::package,
    ensure  => $ensure,
  }
  #TO-DO: default vhost
  @apache::vhost { 'shield':
    ensure         => $ensure,
    priority       => '000',
    ssl_ports      => [],
    doc_root       => $apache::params::web_root_dir,
    allow_override => 'None',
    dir_options    => 'None',
    dir_directives => [
      'Order allow,deny',
      'deny from all',
    ],
  }

  Apache::Conf <| |>

  #TO-DO: realize exported modules
  Apache::Module <| |>

  #TO-DO: realize exporeted vhosts
  Apache::Vhost <| |>

  include apache::monit

}
