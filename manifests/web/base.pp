define rgbank::web::base(
  $ensure = present,
  $version = undef,
  $source = undef,
  $source_type = undef,
  $listen_port = undef,
  $install_dir = undef,
  $db_name = undef,
  $db_user = undef,
  $db_password = undef,
  $db_host = undef,
  $custom_wp_config = undef,
  $enable_header = false,
  $artifactory_server = undef,
  $site_url = undef,
) {
  if $install_dir {
    $install_dir_real = $install_dir
  } else {
    $install_dir_real = "/opt/rgbank-${name}"
  }

  if $ensure == 'absent' {
    file { $install_dir_real:
      ensure  => absent,
      recurse => true,
      force   => true,
    }
  } else {
    wordpress::instance::app { "rgbank_${name}":
      install_dir          => $install_dir_real,
      install_url          => 'http://wordpress.org',
      version              => '4.3.6',
      db_host              => $db_host,
      db_name              => $db_name,
      db_user              => $db_user,
      db_password          => $db_password,
      wp_owner             => 'root',
      wp_group             => '0',
      wp_lang              => '',
      wp_config_content    => $custom_wp_config,
      wp_plugin_dir        => 'DEFAULT',
      wp_additional_config => 'rgbank/wp-proxy-config.php.erb',
      wp_table_prefix      => 'wp_',
      wp_proxy_host        => '',
      wp_proxy_port        => '',
      wp_multisite         => false,
      wp_site_domain       => '',
      wp_debug             => false,
      wp_debug_log         => false,
      wp_debug_display     => false,
      notify               => Service['nginx'],
      wp_config_owner      => nginx,
      wp_config_group      => nginx,
      wp_config_mode       => '0666',
      manage_wp_content    => true,
      wp_content_owner     => nginx,
      wp_content_group     => nginx,
      wp_content_recurse   => true,
      wp_site_url          => "http://${ec2_metadata['public-hostname']}:${listen_port}",
    }

    case $source_type {
      'vcs': {

        file { 'rgbank/git':
          ensure => directory,
          path   => "${install_dir_real}/git",
          owner  => root,
          group  => root,
          mode   => '0755',
        }

        vcsrepo { 'rgbank/git/rgbank':
          ensure   => present,
          path     => "${install_dir_real}/git/rgbank",
          provider => git,
          source   => $source,
          revision => $version,
          require  => File["${install_dir_real}/git"],
        }

        file { 'rgbank/wp-content/themes/rgbank':
          ensure  => link,
          path    => "${install_dir_real}/wp-content/themes/rgbank",
          target  => "${install_dir_real}/git/rgbank/src",
          require => [
            Vcsrepo["${install_dir_real}/git/rgbank"],
            Wordpress::Instance::App["rgbank_${name}"],
          ],
          before  => File["${install_dir_real}/wp-content/uploads"],
        }
      }

      'artifactory': {
        archive::artifactory { "rgbank-build-${version}.tar.gz":
          ensure       => present,
          extract      => true,
          extract_path => "${install_dir_real}/artifactory/rgbank-${version}",
          url          => "http://${artifactory_server}/artifactory/rgbank-web/rgbank-build-${version}.tar.gz",
          archive_path => "${install_dir_real}/artifactory/rgbank-${version}",
          require      => File["${install_dir_real}/artifactory/rgbank-${version}"],
        }

        file { 'rgbank/artifactory':
          ensure => directory,
          path   => "${install_dir_real}/artifactory",
          owner  => root,
          group  => root,
          mode   => '0755',
          purge  => true,
          force  => true,
        }

        file { "rgbank/artifactory/rgbank-${version}":
          ensure => directory,
          path   => "${install_dir_real}/artifactory/rgbank-${version}",
          owner  => root,
          group  => root,
          mode   => '0755',
        }

        file { 'rgbank/wp-content/themes/rgbank':
          ensure  => link,
          path    => "${install_dir_real}/wp-content/themes/rgbank",
          target  => "${install_dir_real}/artifactory/rgbank-${version}",
          require => [
            Archive::Artifactory["rgbank-build-${version}.tar.gz"],
            Wordpress::Instance::App["rgbank_${name}"],
          ],
          before  => File["${install_dir_real}/wp-content/uploads"],
        }

      }

      'http': {
        archive { "rgbank-build-${version}-${name}":
          ensure     => present,
          url        => $source,
          target     => "${install_dir_real}/wp-content/themes/rgbank",
          checksum   => false,
          src_target => '/tmp',
          root_dir   => '.',
          require    => Wordpress::Instance::App["rgbank_${name}"],
          before     => File["${install_dir_real}/wp-content/uploads"],
        }
      }
    }

    file { "${install_dir_real}/wp-content/uploads":
      ensure  => directory,
      path    => "${install_dir_real}/wp-content/uploads",
      owner   => $::nginx::config::global_owner,
      group   => $::nginx::config::global_group,
      recurse => true,
      require => Wordpress::Instance::App["rgbank_${name}"],
    }

    if $::selinux == true {
      exec{"selinux-update-${install_dir_real}":
        path        => $::path,
        command     => "chcon -R system_u:object_r:usr_t:s0 ${install_dir_real}",
        subscribe   => Wordpress::Instance::App["rgbank_${name}"],
        require     => File["${install_dir_real}/wp-content/uploads"],
        refreshonly => true,
      }
    }
  }

  nginx::resource::location { "${name}_root":
    ensure                => $ensure,
    server                => $name,
    location              => '~ \.php$',
    index_files           => ['index.php'],
    fastcgi               => '127.0.0.1:9000',
    www_root              => $install_dir_real,
    fastcgi_script        => undef,
    proxy_read_timeout    => '',
    proxy_connect_timeout => '',
    proxy_send_timeout    => '',
    proxy_set_header      => [],
    proxy_hide_header     => [],
    proxy_pass_header     => [],
    proxy_ignore_header   => [],
  }

  nginx::resource::server { $name:
    ensure               => $ensure,
    listen_port          => $listen_port,
    use_default_location => false,
    www_root             => $install_dir_real,
    index_files          => [ 'index.php' ],
    fastcgi_script       => undef,
  }

  if $ensure == 'absent' {
    file { 'rgbank/variables.php':
      ensure =>  absent,
      path   => "${install_dir_real}/variables.php",
    }
  } else {

    file { 'rgbank/variables.php':
      ensure  => present,
      path    => "${install_dir_real}/variables.php",
      content => epp('rgbank/variables.epp', {
        'version'            => $version,
        'build_source_type'  => $source_type,
        'build_source'       => $source,
        'artifactory_server' => $artifactory_server,
        'enable_header'      => $enable_header,
      }),
      owner   => $::nginx::config::global_owner,
      group   => $::nginx::config::global_group,
      mode    => '0644',
    }
  }
}
