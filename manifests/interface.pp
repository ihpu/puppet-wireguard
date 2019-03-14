# @summary
#   Defines wireguard tunnel interfaces
# @param address
#   List of IP (v4 or v6) addresses (optionally with CIDR masks) to
#   be assigned to the interface.
# @param private_key
#   Private key for data encryption
# @param listen_port
#   The port to listen
# @param ensure
#   State of the interface
# @param peers
#   List of peers for wireguard interface
# @param saveconfig
#    save current state of the interface upon shutdown
# @param config_dir
#   Path to wireguard configuration files
define wireguard::interface (
  Variant[Array,String] $address,
  Integer[1,65535]      $listen_port,
  Optional[String]      $private_key = undef,
  Enum['present','absent'] $ensure = 'present',
  Optional[Array[Struct[
    {
      'PublicKey'  => String,
      'AllowedIPs' => Optional[String],
      'Endpoint'   => Optional[String],
    }
  ]]]                   $peers        = [],
  Boolean               $saveconfig   = true,
  Stdlib::Absolutepath  $config_dir   = $::wireguard::config_dir,
  Boolean               $gen_keys     = false,
) {
  require ::wireguard

  $_private_key = $gen_keys ? {
    true  => 'REPLACE_WITH_GENERATED_KEY',
    false => $private_key
  }
  assert_type(String[1], $_private_key)

  file {"${config_dir}/${name}.conf":
    ensure    => $ensure,
    mode      => '0600',
    owner     => 'root',
    group     => 'root',
    show_diff => false,
    content   => template("${module_name}/interface.conf.erb"),
    notify    => Service["wg-quick@${name}.service"],
  }

  if $gen_keys {
    # config file is saved to template
    # template is the used by update script to build normal config file
    File["${config_dir}/${name}.conf"] {
      path => "${config_dir}/${name}.template"
    }
    exec{"${name}_gen_keys":
      path    => '/usr/bin:/usr/sbin:/bin',
      command => "${config_dir}/helper ${name} genkeys",
      unless  => "/usr/bin/test -f ${config_dir}/keys/${name}.key",
      notify  => Exec["${name}_update_conf"],
    }
    exec{"${name}_update_conf":
      path        => '/bin:/sbin:/usr/bin:/usr/sbin',
      cwd         => $config_dir,
      command     => "${config_dir}/helper ${name} update",
      refreshonly => true,
      notify      => Service["wg-quick@${name}.service"],
    }
    Exec["${name}_gen_keys"]
    ->File["${config_dir}/${name}.conf"]
    ~>Exec["${name}_update_conf"]
  }

  $_service_ensure = $ensure ? {
    'absent' => 'stopped',
    default  => 'running',
  }
  $_service_enable = $ensure ? {
    'absent' => false,
    default  => true,
  }

  service {"wg-quick@${name}.service":
    ensure   => $_service_ensure,
    provider => 'systemd',
    enable   => $_service_enable,
    require  => File["${config_dir}/${name}.conf"],
  }
}
