class apache::monit (
  $ensure = $apache::ensure
) {

  include apache::params

  if defined(Class['monit']) {

#    $ensure    = $apache::params::ensure
    $hostname  = "monit-test.${::fqdn}"
    $web_dir   = "${apache::params::web_root_dir}/${hostname}"
    $web_index = "${apache::params::web_root_dir}/${hostname}/index.html"

    case $ensure {
      /(present)/: {
        $dir_ensure = 'directory'
        if $autoupgrade == true {
          $package_ensure = 'latest'
        } else {
          $package_ensure = 'present'
        }
      }
      /(absent)/: {
        $package_ensure = 'absent'
        $dir_ensure = 'absent'
      }
      default: {
        fail('ensure parameter must be present or absent')
      }
    }

    file { $web_dir:
      ensure  => $dir_ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      recurse => true,
      purge   => true,
    }

    file { $web_index:
      ensure  => $ensure,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => 'monit-test',
    }

    @apache::vhost { $hostname:
      ensure         => $ensure,
      priority       => '999',
      doc_root       => $web_dir,
      allow_override => 'None',
      dir_options    => 'None',
      dir_directives => [
        'Order allow,deny',
        'Allow from all',
      ],
      custom_log     => '/dev/null "-"',
      error_log      => '/dev/null',
      require        => [
        File[$web_dir],
        File[$web_index],
      ],
    }

#    if !defined(Host[$hostname]) {
#      host { $hostname:
#        ip => '127.0.0.1',
#      }
#    }

    #TO-DO: implement url tests
    @monit::service_conf { $apache::params::service_name:
      ensure    => $ensure,
      start     => $apache::params::ensure_start,
      net_tests => [{
        'host'     => $hostname,
        'tcp'      => $apache::params::ports_real,
        'protocol' => 'HTTP',
      }],
      require   => [
        Apache::Vhost[$hostname],
        Service[$apache::params::service_name],
      ],
    }
  }
}
