class apache::external::munin::node::plugin (
  $ensure = $apache::ensure
) {

  include apache::params

#  notify {"--outside---":}

  # We can only check if the classe exists or if it's loaded by the parser before current one
  if defined( '::munin::node' ) {
    #TO-DO: implement url tests

#    notify {"--inside---":}

    case $::osfamily {
      debian : {
        $required_packages = 'libio-all-lwp-perl'
      }
      default: {
        fail("Unsupported platform: ${::osfamily}")
      }
    }

    $plugins = [
      'apache_accesses',
      'apache_processes',
      'apache_volume',
    ]

    # TODO: server status if not defined
    # TODO: specific vhost
    # TODO: add stdlib dependency
    $first_port = values_at(any2array($apache::params::ports), 0)

    @munin::node::plugin::conf { 'apache' :
      ensure => $ensure,
      config => {
        'apache_*' => [
          "env.url http://127.0.0.1:${first_port}/server-status?auto",
        ],
      },
    }

    @munin::node::plugin::required_package { $required_packages :
      ensure => $ensure,
      tag    => $plugins,
    }

    @munin::node::plugin { $plugins :
      ensure    => $ensure,
      required_packages => $required_packages,
      require   => [
        Service[$apache::params::service_name],
        Package[$required_packages],
      ],
    }
  }
}
