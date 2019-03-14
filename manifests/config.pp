# @summary
#  Class configures files and directories for wireguard
# @param config_dir
#   Path to wireguard configuration files
class wireguard::config (
  Stdlib::Absolutepath $config_dir,
  String               $config_dir_mode,
) {

  file {$config_dir:
    ensure => 'directory',
    mode   => $config_dir_mode,
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
