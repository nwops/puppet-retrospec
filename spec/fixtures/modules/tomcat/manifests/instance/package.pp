# Definition: tomcat::instance::package
#
# Private define to install Tomcat from a package.
#
# Parameters:
# - $package_ensure is the ensure passed to the package resource.
# - The $package_name you want to install.
define tomcat::instance::package (
  $package_ensure = 'installed',
  $package_name = undef,
) {
  if $caller_module_name != $module_name {
    fail("Use of private class ${name} by ${caller_module_name}")
  }

  if $package_name {
    $_package_name = $package_name
  } else {
    $_package_name = $name
  }

  package { $_package_name:
    ensure => $package_ensure
  }

}
