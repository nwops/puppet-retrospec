# Definition: tomcat::config::server::host
#
# Configure Host elements in $CATALINA_BASE/conf/server.xml
#
# Parameters:
# - $app_base is the appBase attribute for the Host. This parameter is required
#   unless $host_ensure is set to 'false' or 'absent'.
# - $catalina_base is the base directory for the Tomcat installation.
# - $host_ensure specifies whether you are trying to add or remove the Host
#   element. Valid values are 'true', 'false', 'present', and 'absent'. Defaults
#   to 'present'.
# - $host_name is the name attribute for the Host. Defaults to $name.
# - $parent_service is the Service element this Host should be nested beneath.
#   Defaults to 'Catalina'
# - An optional hash of $additional_attributes to add to the Host. Should be of
#   the format 'attribute' => 'value'.
# - An optional array of $attributes_to_remove from the Host.
define tomcat::config::server::host (
  $app_base              = undef,
  $catalina_base         = $::tomcat::catalina_home,
  $host_ensure           = 'present',
  $host_name             = undef,
  $parent_service        = 'Catalina',
  $additional_attributes = {},
  $attributes_to_remove  = [],
  $server_config         = undef,
) {
  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  validate_re($host_ensure, '^(present|absent|true|false)$')
  validate_hash($additional_attributes)

  if $host_name {
    $_host_name = $host_name
  } else {
    $_host_name = $name
  }

  $base_path = "Server/Service[#attribute/name='${parent_service}']/Engine/Host[#attribute/name='${_host_name}']"

  if $server_config {
    $_server_config = $server_config
  } else {
    $_server_config = "${catalina_base}/conf/server.xml"
  }

  if $host_ensure =~ /^(absent|false)$/ {
    $changes = "rm ${base_path}"
  } else {
    if ! $app_base {
      fail('$app_base must be specified if you aren\'t removing the host')
    }

    $_host_name_change = "set ${base_path}/#attribute/name ${_host_name}"
    $_app_base = "set ${base_path}/#attribute/appBase ${app_base}"

    if ! empty($additional_attributes) {
      $_additional_attributes = suffix(prefix(join_keys_to_values($additional_attributes, " '"), "set ${base_path}/#attribute/"), "'")
    } else {
      $_additional_attributes = undef
    }

    if ! empty(any2array($attributes_to_remove)) {
      $_attributes_to_remove = prefix(any2array($attributes_to_remove), "rm ${base_path}/#attribute/")
    } else {
      $_attributes_to_remove = undef
    }

    $changes = delete_undef_values(flatten([$_host_name_change, $_app_base, $_additional_attributes, $_attributes_to_remove]))
  }

  augeas { "${catalina_base}-${parent_service}-host-${_host_name}":
    lens    => 'Xml.lns',
    incl    => $_server_config,
    changes => $changes,
  }
}
