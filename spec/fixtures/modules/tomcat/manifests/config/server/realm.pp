# Definition: tomcat::config::server::realm
#
# Configure Realm elements in $CATALINA_BASE/conf/server.xml
#
# Parameters:
# - $catalina_base is the base directory for the Tomcat installation.
# - $class_name is the Java class name of the Realm implementation to use.
# - $realm_ensure specifies whether you are adding or removing a
#   Realm element. Valid values are 'true', 'false', 'present', and
#   'absent'. Defaults to 'present'.
# - $parent_service is the `name` attribute for the Service element this Realm
#   should be nested beneath. Defaults to 'Catalina'.
# - $parent_engine is the `name` attribute for the Engine element this Realm
#   should be nested beneath. Defaults to 'Catalina'.
# - $parent_host is the `name` attribute for the Host element this Realm
#   should be nested beneath.
# - $parent_realm is the `name` attribute for the Realm element this Realm
#   should be nested beneath.
# - An optional hash of $additional_attributes to add to the Realm. Should
#   be of the format 'attribute' => 'value'.
# - An optional array of $attributes_to_remove from the Realm.
define tomcat::config::server::realm (
  $catalina_base         = $::tomcat::catalina_home,
  $class_name            = $name,
  $realm_ensure          = 'present',
  $parent_service        = 'Catalina',
  $parent_engine         = 'Catalina',
  $parent_host           = undef,
  $parent_realm          = undef,
  $additional_attributes = {},
  $attributes_to_remove  = [],
  $purge_realms          = $::tomcat::purge_realms,
  $server_config         = undef,
) {

  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }
  validate_re($realm_ensure, '^(present|absent|true|false)$')
  validate_hash($additional_attributes)
  validate_array($attributes_to_remove)
  validate_bool($purge_realms)

  if $purge_realms and ($realm_ensure =~ /^(absent|false)$/) {
    fail('$realm_ensure must be set to \'true\' or \'present\' to use $purge_realms')
  }

  if $purge_realms {
    $_purge_realms = 'rm Server//Realm'
  } else {
    $_purge_realms = undef
  }

  $engine_path = "Server/Service[#attribute/name='${parent_service}']/Engine[#attribute/name='${parent_engine}']"

  # The Realm may be nested under a Host element.
  if $parent_host {
    $host_path = "${engine_path}/Host[#attribute/name='${parent_host}']"
  } else {
    $host_path = $engine_path
  }

  # The Realm could also be nested under another Realm element if the parent realm is a CombinedRealm.
  if $parent_realm {
    $path = "${host_path}/Realm[#attribute/className='${parent_realm}']/Realm"
  }
  else {
    $path = "${host_path}/Realm"
  }

  if $server_config {
    $_server_config = $server_config
  } else {
    $_server_config = "${catalina_base}/conf/server.xml"
  }

  if $realm_ensure =~ /^(absent|false)$/ {
    $changes = "rm ${path}[#attribute/className='${class_name}']"
  }
  else {

    $_class_name = "set ${path}/#attribute/className ${class_name}"

    if ! empty($additional_attributes) {
      $_additional_attributes = suffix(prefix(join_keys_to_values($additional_attributes, " '"), "set ${path}[#attribute/className='${class_name}']/#attribute/"), "'")
    } else {
      $_additional_attributes = undef
    }
    if ! empty(any2array($attributes_to_remove)) {
      $_attributes_to_remove = prefix(any2array($attributes_to_remove), "rm ${path}[#attribute/className='${class_name}']/#attribute/")
    } else {
      $_attributes_to_remove = undef
    }

    $changes = delete_undef_values(flatten([ $_purge_realms, $_class_name, $_additional_attributes, $_attributes_to_remove ]))
  }

  augeas { "${catalina_base}-${parent_service}-${parent_engine}-${parent_host}-${parent_realm}-realm-${class_name}":
    lens    => 'Xml.lns',
    incl    => $_server_config,
    changes => $changes,
  }

}
