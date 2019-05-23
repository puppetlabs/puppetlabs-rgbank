define rgbank::web (
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $version = hiera('rgbank-build-version', 'master'),
  $source = hiera('rgbank-build-path', 'http://gitlab.inf.puppet.vm/rgbank/rgbank-web'),
  $source_type = 'vcs', #hiera('rgbank-build-source-type', 'vcs'),
  $artifactory_server = hiera('rgbank::artifactory_server', puppetdb_query('inventory[facts] { trusted.extensions.pp_role = "artifactory" }')[0]['facts']['fqdn'], undef),
  $listen_port = '8060',
  $install_dir = undef,
  $image_tag = 'latest',
  $enable_header = hiera('rgbank::web::enable_header', false),
) {
    rgbank::web::base { $name:
      ensure => absent,
    }

    rgbank::web::docker { $name:
      db_name     => $db_name,
      db_user     => $db_user,
      db_password => $db_password,
      db_host     => $db_host,
      image_tag   => $image_tag,
      listen_port => $listen_port,
    }

    if $::selinux == true {
      if (! defined(Selinux::Port["allow-httpd-${listen_port}"])) {
        selinux::port { "allow-httpd-${listen_port}":
          context  => 'http_port_t',
          port     => $listen_port,
          protocol => 'tcp',
          before   => [Rgbank::Web::Base[$name]],
        }
      }

      if (! defined(Selinux::Boolean['httpd_can_network_connect'])) {
        selinux::boolean { 'httpd_can_network_connect':
          ensure     => true,
          persistent => true,
          before     => [Rgbank::Web::Base[$name]],
        }
      }
    }
  }

  firewall { "000 accept rgbank web connections for ${name}":
    dport  => $listen_port,
    proto  => tcp,
    action => accept,
  }
}

Rgbank::Web produces Http {
  name => $name,
  ip   => $::ipaddress,
  port => $listen_port,
  host => $::trusted['certname'],
  path => '/',
}

Rgbank::Web consumes Database {
  db_name     => $database,
  db_host     => $host,
  db_user     => $user,
  db_password => $password,
}

Rgbank::Web consumes Vinfrastructure { }
