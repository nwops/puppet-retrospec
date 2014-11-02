class includes-class{

  include class1
  include class2
  include class3


  require class4
  require class5

  $var1 = 'true'

  file{"dummytest":
    ensure => directory

  }

  file{"dummytest":
    ensure => directory
  }

  if $var1 == 'true'{
    include class6
  }

}