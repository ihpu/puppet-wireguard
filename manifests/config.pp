# @summary
#  Class configures files and directories for wireguard
# @param config_dir
#   Path to wireguard configuration files
class wireguard::config (
  Stdlib::Absolutepath    $config_dir,
) {

  file {$config_dir:
    ensure => 'directory',
    mode   => '0700',
    owner  => 'root',
    group  => 'root',
  }
  ->file {'wg_conf_helper':
    ensure => present,
    path   => "${config_dir}/helper",
    source => 'puppet:///modules/wireguard/helper',
    mode   => '0744',
  }

}
