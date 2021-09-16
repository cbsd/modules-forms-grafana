add validator

http_conn_validator { 'grafana-conn-validator' :
  host     => 'localhost',
  port     => '3000',
  use_ssl  => false,
  test_url => '/public/img/grafana_icon.svg',
  require  => Class['grafana'],
}
-> ... dashboard



or sleep 2-3 after: service grafana start
