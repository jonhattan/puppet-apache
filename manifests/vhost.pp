define apache::vhost(
  $ensure           = present,
  $server_name      = $name,
  $enabled          = true,
  $priority         = '010',
  $ips              = [ '*' ],
  $content          = '',
  $ensure_www       = undef,
  $ports            = $apache::params::ports,
#TO-DO: implement   ssl
  $ssl_ports        = $apache::params::ssl_ports,
  $server_aliases   = [],
  $vhost_directives = [],
  $doc_root         = '',
  $dir_options      = [],
  $allow_override   = 'None',
  $dir_directives   = [],
  $vhost_directives = [],
  $server_admin     = '',
  $log_level        = '',
  $error_log        = '',
  $custom_log       = '',
  $ensure_hosts_ent = true,
  $host_ent_ip      = undef,
  $manage_doc_root  = false,
) {
  require apache::params

  Apache::Vhost <| |> ~> Service[$apache::params::service_name]

  $file_name = "${apache::params::vhost_dir}/${name}"
  $file_en_name = "${apache::params::vhost_en_dir}/${priority}_${name}"

  $ports_real = any2array($ports)
  $dir_options_real = any2array($dir_options)

#  #TO-DO: add stdlib to requirements and validate params
#  $valid_canonical_www = [ 'present', 'absent']
#  if $canonical_www != undef {
#    validate_re($canonical_www, $valid_canonical_www)
#    $redirect_prefix 
#  }

  case $ensure {
    present: {
      if $content != '' {
        $content_real = $content
      }
      else {
        case $ensure_www {
          present: {
            $source_prefix = ''
            $destination_prefix = 'www.'
          }
          absent: {
            $source_prefix = 'www.'
            $destination_prefix = ''
          }
          undef: {
            $source_prefix = ''
            $destination_prefix = ''
          }
          default: { err ( "Unknown ensure_www value: '${ensure_www}'" ) }
        }
        $content_real = template('apache/vhost.erb')
      }
      $ensure_link = $enabled ? {
        true    => link,
        default => absent,
      }
    }
    absent: {
      $ensure_link = absent
    }
    default: { err ( "Unknown ensure value: '$ensure'" ) }
  }

  file { $file_name:
    ensure  => $ensure,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    replace => true,
    content => $content_real,
    require => File[$apache::params::vhost_dir],
  }

  file { $file_en_name:
    ensure => $ensure_link,
    target => $file_name,
  }

  if $manage_doc_root {
    file { $doc_root:
      ensure  => $apache::dir_ensure,
      owner   => 'root',
      group   => $apache::params::group,
      mode    => '2640',
    }
  }

  if $ensure_hosts_ent and !defined(Host[$server_name]) {
    host { $server_name:
      ensure       => $ensure,
      ip           => $host_ent_ip ? {
        undef   => $ips ? {
          '*'     => '127.0.0.1',
          default => inline_template('<% if @ips.kind_of?(Array) 
            -%><%= @ips.first %><% else -%><%= @ips %><% end -%>'),
        },
        default => $host_ent_ip
      },
      host_aliases => $server_aliases,
    }
  }

}
