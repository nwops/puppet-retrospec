# Definition: tomcat::service
#
# Service management for Tomcat.
#
# Parameters:
# - $catalina_home is the root of the Tomcat installation.
# - $catalina_base is the base directory for the Tomcat installation.
# - Whether or not to $use_jsvc for service management. Boolean defaulting to
#   false. If both $use_jsvc and $use_init are false,
#   $CATALINA_BASE/bin/catalina.sh start and $CATALIN/A_BASE/bin/catalina.sh
#   stop are used for service management.
# - If using jsvc, optionally set java_home.  Has no affect unless
#   $use_jsvc = true.
# - $service_ensure is passed on to the service resource.
# - $service_enable specifies whether the tomcat service should be enabled on
#   on boot. Valid options are 'true' or 'false'. Defaults to 'undef', will be
#   programmatically set to 'true' if $use_init is true AND
#   $service_ensure == 'running'
# - Whether or not to $use_init for service management. Boolean defaulting to
#   false. If both $use_jsvc and $use_init are false,
#   $CATALINA_BASE/bin/catalina.sh start and $CATALIN/A_BASE/bin/catalina.sh
#   stop are used for service management.
# - The $service_name to use when $use_init is true.
# - The $start_command to use for the service
# - The $stop_command to use for the service
define tomcat::service (
  $catalina_home  = undef,
  $catalina_base  = undef,
  $use_jsvc       = false,
  $java_home      = undef,
  $service_ensure = running,
  $service_enable = undef,
  $use_init       = false,
  $service_name   = undef,
  $start_command  = undef,
  $stop_command   = undef,
) {

  validate_bool($use_jsvc)
  validate_bool($use_init)

  if $use_jsvc and $use_init {
    fail('Only one of $use_jsvc and $use_init can be set to true')
  }

  if $use_init and ! $service_name {
    fail('$service_name must be specified when $use_init is set to true')
  }

  if $service_enable != undef and ! $use_init {
    warning('$use_init must be set to true when $service_enable is set')
  }

  if $use_init and ($catalina_home or $catalina_base) {
    warning('$catalina_home and $catalina_base have no affect when $use_init = true')
  }

  if $java_home and ! $use_jsvc {
    warning('$java_home has no affect unless $use_jsvc = true')
  }

  if $java_home and $start_command {
    warning('$java_home is used in the $start_command, so this may not work as planned')
  }

  if ! $catalina_home {
    $_catalina_home = $::tomcat::catalina_home
  } else {
    $_catalina_home = $catalina_home
  }

  if ! $catalina_base {
    $_catalina_base = $::tomcat::catalina_home
  } else {
    $_catalina_base = $catalina_base
  }

  if $use_jsvc {
    if $java_home {
      $_jsvc_home = "-home ${java_home} "
    } else {
      $_jsvc_home = undef
    }
    $_service_name = "tomcat-${name}"
    $_hasstatus    = false
    $_hasrestart   = false
    $_start        = $start_command ? {
      undef   => "export CATALINA_HOME=${_catalina_home}; export CATALINA_BASE=${_catalina_base};
                 \$CATALINA_BASE/bin/jsvc \
                   ${_jsvc_home}-user ${::tomcat::user} \
                   -classpath \$CATALINA_BASE/bin/bootstrap.jar:\$CATALINA_BASE/bin/tomcat-juli.jar \
                   -outfile \$CATALINA_BASE/logs/catalina.out \
                   -errfile \$CATALINA_BASE/logs/catalina.err \
                   -pidfile \$CATALINA_BASE/logs/jsvc.pid \
                   -Dcatalina.home=\$CATALINA_HOME \
                   -Dcatalina.base=\$CATALINA_BASE \
                   -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
                   -Djava.util.logging.config.file=\$CATALINA_BASE/conf/logging.properties \
                   org.apache.catalina.startup.Bootstrap",
      default => $start_command,
    }
    $_stop         = $stop_command ? {
      undef   => "export CATALINA_HOME=${_catalina_home}; export CATALINA_BASE=${_catalina_base};
                 \$CATALINA_BASE/bin/jsvc \
                   -pidfile \$CATALINA_BASE/logs/jsvc.pid \
                   -stop org.apache.catalina.startup.Bootstrap",
      default => $stop_command,
    }
    $_status       = "ps p `cat ${_catalina_base}/logs/jsvc.pid` > /dev/null"
    $_provider     = 'base'
  } elsif $use_init {
    $_service_name = $service_name
    $_hasstatus    = true
    $_hasrestart   = true
    $_start        = $start_command
    $_stop         = $stop_command
    $_status       = undef
    $_provider     = undef
  } else {
    $_service_name = "tomcat-${name}"
    $_hasstatus    = false
    $_hasrestart   = false
    $_start        = $start_command ? {
      undef   => "su -s /bin/bash -c '${_catalina_base}/bin/catalina.sh start' ${::tomcat::user}",
      default => $start_command
    }
    $_stop         = $stop_command ? {
      undef   => "su -s /bin/bash -c '${_catalina_base}/bin/catalina.sh stop' ${::tomcat::user}",
      default => $stop_command
    }
    $_status       = "ps aux | grep 'catalina.base=${_catalina_base} ' | grep -v grep"
    $_provider     = 'base'
  }

  if $use_init {
    if $service_enable != undef {
      validate_bool($service_enable)
      $_service_enable = $service_enable
    } else {
      $_service_enable = $service_ensure ? {
        'running' => true,
        true      => true,
        default   => undef,
      }
    }
  } else {
    $_service_enable = undef
  }

  service { $_service_name:
    ensure     => $service_ensure,
    enable     => $_service_enable,
    hasstatus  => $_hasstatus,
    hasrestart => $_hasrestart,
    start      => $_start,
    stop       => $_stop,
    status     => $_status,
    provider   => $_provider,
  }
}
