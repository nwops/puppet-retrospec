class one_resource::array_param(
   $some_var = ['default'],
   $double_array = [1, [2,3]]

) {
  file{'/tmp/test':
    ensure => present,
    content => $some_var[0]
  }
  file{'/tmp/test2':
    ensure => present,
    content => $double_array[1][1]
  }

}
