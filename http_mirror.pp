class nagios::check::http_mirror($host = $fqdn) {
  $mirrorpackages = hiera_array('nagios::check::http_mirror::packages', [])
  $plugindir = hiera('nagios::client::plugins_dir')
  $packages = hiera_array('nagios::client::packages', [])
  $service = hiera('nagios::client::service', "nrpe")
  $mirrors = hiera_hash('nagios::check::http_mirror::mirrors', undef)

  package { $mirrorpackages:
    ensure => present
  }
  ->
  templatedfile { "check_mirror":
    module  => "nagios",
    path    => "${plugins_dir}/check_mirror",
    mode    => 755,
    notify  => Service[$service],
    require => Package[$packages],
  }

  # Server command for collection into configs:
  @@nagios::server::command { "check_mirror":
    command_line => '$USER1$/check_mirror -H $ARG1$ -F $ARG2$ -h $ARG3$ -f $ARG4$ -d $ARG5$',
  }
 
  if $mirrors {
    create_resources('nagios::check::http_mirror::mirror', $mirrors)
  }
}


# TODO : check_interval is in minutes, whereas maxdiff is in seconds...
define nagios::check::http_mirror::mirror(
  $host = $fqdn, $upstream, $upstream_path, $our_host, $our_path, $description, $maxdiff = "1440", $contacts = "", $check_interval = "720") {

  nagios::server::check { "mirror-${host}-${upstream}":
    host          => $host,
    cmd           => "mirror",
    template_name => "service-5arg",
    description   => $description,
    arg1          => $upstream,
    arg2          => $upstream_path,
    arg3          => $our_host,
    arg4          => $our_path,
    arg5          => $maxdiff,
    contacts      => $contacts,
    # Twice a day by default is plenty enough :
    check_interval => $check_interval,
  }
}
