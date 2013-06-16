define apache::module(
  $package,
  $ensure       = present,
  $enabled      = true,
  $conf_content = '',
  $load_content = ''
) {
  require apache::params

  Apache::Module <| |> ~> Service[$apache::params::service_name]

  if !defined(Package[$package]) {
    package { $package:
      ensure => $ensure,
    }
  }

  $file_name_load = "${apache::params::mod_dir}/${name}.load"
  $file_en_name_load = "${apache::params::mod_en_dir}/${name}.load"

  $file_name_conf = "${apache::params::mod_dir}/${name}.conf"
  $file_en_name_conf = "${apache::params::mod_en_dir}/${name}.conf"

  case $ensure {
    present: {
      file { $file_name_load:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        replace => $load_content ? {
          ''      => false,
          default => true,
        },
        content => $load_content,
        require => Package[$package],
      }

      file { $file_name_conf:
        ensure  => $ensure,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        replace => $conf_content ? {
          ''      => false,
          default => true,
        },
        content => $conf_content,
        require => Package[$package],
      }

      if $enabled {
        file { $file_en_name_load:
          ensure  => link,
          target  => $file_name_load,
          require => Package[$package],
        }
        file { $file_en_name_conf:
          ensure  => link,
          target  => $file_name_conf,
          require => File[$file_en_name_load],
        }
      }
    }
    absent: {
      # TO-DO: think about what should happen here
#      file { $file_name_load:
#        ensure  => $ensure,
#      }
#      file { $file_name_conf:
#        ensure  => $ensure,
#      }
    }
    default: { err ( "Unknown ensure value: '$ensure'" ) }
  }

#  # We can't depend on the class because it generates a cycling reference
#  Package["${requires}"] -> Drafts::Apache-modules["${name}"]
#
#  $path = "/usr/sbin/"
#  $apache2_mods = "/etc/apache2/mods"
#
#  case $ensure {
#    present: {
#      $a2command = "a2enmod"
#      $command = "${path}${a2command} ${name}"
#      exec { "${command}":
#        unless  => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
#        notify  => Exec['force-reload-apache2'],
#      }
#    }
#    absent: {
#      $a2command = "a2dismod"
#      $command = "${path}${a2command} ${name}"
#      exec { "${command}":
#        onlyif  => "/bin/readlink -e ${apache2_mods}-enabled/${name}.load",
#        notify  => Exec['force-reload-apache2'],
#      }
#    }
#    default: { err ( "Unknown ensure value: '$ensure'" ) }
#  }

}
