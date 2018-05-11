class nested_param {
  resharder::instance { '1' :
    src_cluster_addrs => [
      { 'addr' => "127.0.0.1:43013", 'snapshot-url' => "http://127.0.0.1:2990/1/snaps/", },
      { 'addr' => "127.0.0.1:43014", 'snapshot-url' => "http://127.0.0.1:2990/2/snaps/", },
      { 'addr' => "127.0.0.1:43015", 'snapshot-url' => "http://127.0.0.1:2990/3/snaps/", },
      { 'addr' => "127.0.0.1:43016", 'snapshot-url' => "http://127.0.0.1:2990/4/snaps/", },
    ]
  }
}