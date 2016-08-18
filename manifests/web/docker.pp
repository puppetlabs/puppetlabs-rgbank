class rgbank::web::docker(
  $db_name,
  $db_host,
  $db_user,
  $db_password,
  $image_tag = 'latest',
  $listen_port = '80'
) {
  docker::image {'ccaum/rgbank-web': }

  docker::run { 'rgbank-web':
    image   => 'ccaum/rgbank-web',
    ports   => [$listen_port],
    expose  => ['80'],
    env     => [
      'DB_NAME'     => $db_name,
      'DB_PASSWORD' => $db_password,
      'DB_USER'     => $db_user,
      'DB_HOST'     => $db_host,
    ],
    command => 'apache2ctl -D FOREGROUND',
  }

  firewall { '000 accept rgbank web connections':
    dport  => $listen_port,
    proto  => tcp,
    action => accept,
  }
}
