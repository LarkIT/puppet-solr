# == Class: solr::config
#
# Full description of class solr here.
#
# === Parameters
#
#
# === Variables
#
#
# === Examples
#
#
# === Copyright
#
# GPL-3.0+
#
class solr::config {

  anchor{'solr::config::begin':}

  # make OS specific changes
  case $::osfamily {
    'redhat': { }
    'debian':{
      file {'/usr/java':
        ensure  => directory,
        require => Anchor['solr::config::begin'],
      }

      # setup a sym link for java home
      file {'/usr/java/default':
        ensure  => 'link',
        target  => '/usr/lib/jvm/java-7-openjdk-amd64',
        require => File['/usr/java'],
        before  => File['/etc/default/jetty'],
      }
    }
    default: {
      fail("Unsupported OS ${::osfamily}.  Please use a debian or \
redhat based system")
    }
  }

  # create the conf directory
  file {$solr::solr_home_conf:
    ensure  => directory,
    require => Anchor['solr::config::begin'],
  }

  file{"${solr::solr_home}/solr":
    ensure  => directory,
    owner   => $solr::jetty_user,
    group   => $solr::jetty_user,
    recurse => true,
    require => File[$solr::solr_home_conf],
  }

  # setup logging
  file {"${solr::solr_home}/etc/jetty-logging.xml":
    ensure  => file,
    owner   => $solr::jetty_user,
    group   => $solr::jetty_user,
    source  => 'puppet:///modules/solr/jetty-logging.xml',
    #require => File["${solr::solr_home}/solr"],
    require => File[$solr::solr_home_conf],
  }

  # setup default jetty configuration file.
  file {'/etc/default/jetty':
    ensure  => file,
    content => template('solr/jetty.erb'),
    require => File ["${solr::solr_home}/etc/jetty-logging.xml"],
  }

  if versioncmp($solr::version, '4.4.0') < 0 {
    # VERY old Solr needs solr.xml to contain cores
    concat {"${solr::solr_home}/solr/solr.xml":
      ensure => present,
      owner  => $solr::jetty_user,
      group  => $solr::jetty_group,
      mode   => '0644',
      notify => Service['jetty'],
    }

    concat::fragment {'solr.xml-header':
      target => "${solr::solr_home}/solr/solr.xml",
      source => 'puppet:///modules/solr/_solr.xml_header',
      order  => '01',
    }

    #ensure_resource('solr::core', "default_${solr::solr_hostname}")

    concat::fragment {'solr.xml-footer':
      target  => "${solr::solr_home}/solr/solr.xml",
      content => "  </cores>\n</solr>\n",
      order   => '99',
    }

  }

  # setup the service level entry
  file {'/etc/init.d/jetty':
    ensure  => file,
    mode    => '0755',
    content => template('solr/jetty.sh.erb'),
    require => File ['/etc/default/jetty'],
  }

  # log file for jetty
  file {'/var/log/jetty':
    ensure  => directory,
    require => File ['/etc/init.d/jetty'],
  }

  file {'/var/cache/jetty':
    ensure  => directory,
    require => File ['/var/log/jetty'],
  }

  anchor {'solr::config::end':
    require => File ['/var/cache/jetty'],
  }

}
