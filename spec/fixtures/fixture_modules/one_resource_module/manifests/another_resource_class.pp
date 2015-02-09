class one_resource::another_resource(
  $var1 = 'value1',
  $var2 = 'value2',
  $file_name = '/tmp/test3',
  $config_base_path = '/etc/hammer',
  $config_set     = $one_resource::params::var1,

) inherits one_resource::params {
  $some_var = "oohhhh"
  $concat_var = "${file_name}/test3183/${some_var}"
  $cli_modules = "${config_base_path}/cli.modules.d"

  file{'/tmp/test2':
    ensure => present,
  }
  file{$file_name:
    ensure => present,
    content => $concat_var
  }
  if $file_name {
    $if_var1 = 'if_var1_value1'
    file{"$file_name/3":
      ensure => present,
    }
  }
  else {
    $if_var1 = 'if_var1_value2'
  }
}