class one_resource::params(
  $param1_var1 = 'param1_value'
){
  $var1 = 'params_class_value1'
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