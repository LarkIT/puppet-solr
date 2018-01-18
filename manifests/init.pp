# == Class: solr
#
# Installs solr using the embedded version of jetty.
# Configures solr and starts the service.
#
# Note, if you are using Centos, you will most likely need to configure
# your firewall rules like so
#     add IP Tables
#     /sbin/iptables -I INPUT 1 -p tcp --dport 8983 -j ACCEPT
#     /sbin/service iptables save
#     service iptables restart
#
# === Parameters
#
# [*url*]
#   The url of the source repository for apache jetty.
#   Default: 'http://mirrors.gigenet.com/apache/lucene/solr',
#
# [*version*]
#   The version to install.
#   Default: '4.10.3'.
#
# [*jetty_user*]
#   Run Jetty as this user ID (default: solr)
#   Note, creates this user.
#
# [*jetty_host*]
#   Listen to connections from this network host
#   Use 0.0.0.0 as host to accept all connections.
#   Default: 127.0.0.1
#
# [*jetty_port*]
#   The network port used by Jetty
#   Default Port: 8983
#
# [*timeout*]
#   The timeout used for downloading the solr package.
#   Default: 120 seconds.
#
# === Variables
#
# [*solr_home*]
#   The home directory for solr.
#
# [*solr_home_conf*]
#   The solr conf directory where schema's should be installed.
#
# [*solr_home_src*]
#   The source directory for solr.
#
# [*solr_home_example_dir*]
#   The directory that contains the example directory.
#
# === Examples
#
# include solr
#
# === Copyright
#
# GPL-3.0+
#
class solr (
  $url         = $solr::params::url,
  $version     = $solr::params::version,
  $jetty_user  = $solr::params::jetty_user,
  $jetty_group = $solr::params::jetty_group,
  $jetty_host  = $solr::params::jetty_host,
  $jetty_port  = $solr::params::jetty_port,
  $timeout     = $solr::params::timeout,
) inherits ::solr::params{

  ## === Variables === ##
  $solr_home      = '/opt/solr'
  $solr_home_conf = "${solr_home}/conf"
  $solr_home_src  = "/opt/solr-${version}"
  $solr_home_example_dir = "${solr_home}/example/collection1"

  anchor{'solr::begin':}

  class{'solr::install':
    require => Anchor['solr::begin'],
  }

  class{'solr::config':
    require => Class['solr::install'],
  }

  class{'solr::service':
    subscribe => Class['solr::config'],
  }

  anchor{'solr::end':
    require => Class['solr::service'],
  }
}
