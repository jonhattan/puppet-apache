define apache::conf(
  $ensure     = present,
  $directives = [],
  $content    = '',
) {
  require apache::params

  Apache::Conf <| |> ~> Service[$apache::params::service_name]

  $file_name = "${apache::params::config_dir}/${name}"

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
        $content_real = template('apache/conf.erb')
      }
    }
    absent: {
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
    require => File[$apache::params::config_dir],
  }

}
