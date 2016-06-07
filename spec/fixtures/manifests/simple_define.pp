define define_test(
  String $features_location,
  String $source,                 # this is the source of the install media
  String $backup_root_dir        = 'c:\backup',
  String $install_type           = 'default',  # this is the "role" used when installing
  Hash   $install_options        = {},
  Hash   $install_accounts       = {}, # a hash of acount types and account passwords
  Hash   $install_account_passwords = {}, # a hash of account names and passwords
  String $instance_name          = 'MSSQLSERVER',
  Hash   $ssdt_install_options   = {}
  ) {
    if true {
      $value = $::kernel
    }
    notify{$value:}

    case $install_type {
      'custom': {
        if empty($install_options) {
          fail("Install type: ${install_type} specified but no install options given")
        }
        $merged_options = $install_options
      }
      default: {
        $install_flags = {
          'ENU'=>'True',
          'UpdateEnabled'=>'True',
          'ERRORREPORTING'=>'False',
          'USEMICROSOFTUPDATE'=>'False',
          'UpdateSource'=>'MU',
          'HELP'=>'False',
          'INDICATEPROGRESS'=>'False',
          'X86'=>'False',
          'INSTALLSHAREDDIR'=>'C:\Program Files\Microsoft SQL Server',
          'INSTALLSHAREDWOWDIR'=>'C:\Program Files (x86)\Microsoft SQL Server',
          'INSTANCENAME'=>'MSSQLSERVER',
          'SQMREPORTING'=>'False',
          'INSTANCEID'=>'MSSQLSERVER',
          'INSTANCEDIR'=>'C:\Program Files\Microsoft SQL Server',
          'AGTSVCACCOUNT'=>'NT Service\SQLSERVERAGENT',
          'AGTSVCSTARTUPTYPE'=>'Automatic',
          'COMMFABRICPORT'=>'0',
          'COMMFABRICNETWORKLEVEL'=>'0',
          'COMMFABRICENCRYPTION'=>'0',
          'MATRIXCMBRICKCOMMPORT'=>'0',
          'SQLSVCSTARTUPTYPE'=>'Automatic',
          'FILESTREAMLEVEL'=>'0',
          'ENABLERANU'=>'False',
          'SQLCOLLATION'=>'SQL_Latin1_General_CP1_CI_AS',
          'SQLSVCACCOUNT'=>'NT Service\MSSQLSERVER',
          'SQLSYSADMINACCOUNTS'=>'sqlserver\vagrant',
          'ASSYSADMINACCOUNTS' => 'sqlserver\vagrant',
          'ADDCURRENTUSERASSQLADMIN'=>'False',
          'TCPENABLED'=>'1',
          'NPENABLED'=>'0',
          'BROWSERSVCSTARTUPTYPE'=>'Disabled',
          'FTSVCACCOUNT'=>'NT Service\MSSQLFDLauncher',
          'MEDIALAYOUT' => 'Full'
        }
        $merged_ssdt_install_options = merge({
          'ACTION' => 'Install', 'ROLE' => 'AllFeatures_WithDefaults', 'ENU' => 'True', 'QUIET' => 'True', 'UpdateEnabled' => 'True',
          'ERRORREPORTING' => 'False', 'USEMICROSOFTUPDATE' => 'False', 'FEATURES' => 'SSDTBI,SNAC_SDK',
          'UpdateSource' => 'D:\tmp\Updates', 'HELP' => 'False', 'INDICATEPROGRESS' => 'False', 'X86' => 'False',
          'INSTALLSHAREDDIR' => 'E:\Apps', 'SQMREPORTING' => 'False', 'INSTANCEDIR' => 'E:\data' }, $ssdt_install_options, $install_accounts, $install_account_passwords)
        $merged_options = merge($install_flags, $install_options, $install_accounts, $install_account_passwords)
      }
    }

  # we cannot lay down a config file since the sqlserver type does this internally
  # so we are going to specify the install options which accomplishes the same thing
  # we could also do something cool like read a file that contains the install options
  # and convert it to a hash in order to supply some defaults
  # however the problem with this approach is client specific data would need to be
  # in this module or some other module.  So instead, we allow the user to specifiy
  # any client specific install switched and we merge them with the defaults.  Any passed in switches
  # will override the the default switches.  The install accounts are merged in last and will
  # override anything in the install options.  This allows us to specific accounts on a per node basis
  class{ 'sql::install':
    sql_install_flags => $merged_options,
    instance_name     => $instance_name,
    installer_source  => $source,
    features_location => $features_location,
    ssdt_options      => $merged_ssdt_install_options,
  } ->
  sql::backup{$instance_name:
    backup_root_dir => $backup_root_dir
  } ->
  class{'sql::login':}
  }
