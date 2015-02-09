class one_resource::params(
  $param1_var = 'param1_value'
){
  $var1 = 'value1'
  $var2 = 'value2'

  case $::osfamily{
    'windows': {
      $osfamily_var = 'windows'
    }
    'redhat': {
      $osfamily_var = 'redhat'
    }
    default: {
      $osfamily_var = 'default'
    }

  }
}