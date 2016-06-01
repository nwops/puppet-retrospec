

it do
  is_expected.to contain_notify("$value")
end

it do
  is_expected.to contain_class("sql::install")
    .with({
      "sql_install_flags" => "$merged_options",
      "instance_name" => "MSSQLSERVER",
      "installer_source" => :undef,
      "features_location" => :undef,
      "ssdt_options" => "$merged_ssdt_install_options",
      "that_comes_before" => 'Sql::backup[MSSQLSERVER]',
    })
end

it do
  is_expected.to contain_sql__backup("MSSQLSERVER")
    .with({
      "backup_root_dir" => "c:\\backup",
      "that_requires" => 'Class[sql::install]',
    })
end

it do
  is_expected.to contain_class("sql::login")
end
