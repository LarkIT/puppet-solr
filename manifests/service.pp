# == Class: solr::service
#
# === Parameters
#
#
# === Variables
#
# === Examples
#
#
# === Copyright
#
# GPL-3.0+
#
class solr::service {
  anchor {'solr::service::begin':}
  service {'jetty':
    ensure    => running,
    require   => Anchor['solr::service::begin'],
    subscribe => File["${solr::solr_home}/solr"]
  }
  anchor {'solr::service::end':
    require => Service['jetty'],
  }
}
