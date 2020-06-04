class rgbank::web (
  $site_name,
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $version = lookup('rgbank-build-version', String, first, 'master'),
  $source = lookup('rgbank::build-path', String, first, 'http://cdpe-carl-docker.delivery.puppetlabs.net/ccaum/rgbank-application.git'),
  $source_type = lookup('rgbank-build-source-type', String, first, 'vcs'),
  $artifactory_server = lookup('rgbank::artifactory_server', undef, undef, 'artifactory.delivery.puppetlabs.net'),
  $listen_port = 8060,
  $install_dir = undef,
  $image_tag = 'latest',
  $enable_header = lookup('rgbank::web::enable_header', default => false),
  $use_docker = false,
  $site_url = lookup('rgbank::site_url', String, first, 'localhost'),
) {

  if $use_docker {
    rgbank::web::base { $site_name:
      ensure => absent,
    }

    rgbank::web::docker { $site_name:
      db_name     => $db_name,
      db_user     => $db_user,
      db_password => $db_password,
      db_host     => $db_host,
      image_tag   => $image_tag,
      listen_port => $listen_port,
    }
  } else {
    rgbank::web::base { $site_name:
      db_name            => $db_name,
      db_user            => $db_user,
      db_password        => $db_password,
      db_host            => $db_host,
      version            => $version,
      source             => $source,
      source_type        => $source_type,
      listen_port        => $listen_port,
      install_dir        => $install_dir,
      enable_header      => $enable_header,
      artifactory_server => $artifactory_server,
      site_url           => $site_url,
    }

    if $::selinux == true {
      #if (! defined(Selinux::Port["allow-httpd-${listen_port}"])) {
      #  selinux::port { "allow-httpd-${listen_port}":
      #    context  => 'http_port_t',
      #    port     => $listen_port,
      #    protocol => 'tcp',
      #    before   => [Rgbank::Web::Base[$site_name]],
      #  }
      #}

      if (! defined(Selinux::Boolean['httpd_can_network_connect'])) {
        selinux::boolean { 'httpd_can_network_connect':
          ensure     => true,
          persistent => true,
          before     => [Rgbank::Web::Base[$site_name]],
        }
      }
    }
  }

  firewall { "000 accept rgbank web connections for ${site_name}":
    dport  => $listen_port,
    proto  => tcp,
    action => accept,
  }
}
