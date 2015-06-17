# == Type: solr::schema
#
# creates a solr schema file for use in core
#
# === Parameters
#
# [*ensure*]
#   Passed to file resource
#
# [*dir*]
#   Directory to create schema file in
#
# [*source*]
#   The schema file source. This could be useful to source the file from
#   another module or server.
#
# [*content*]
#   (instead of source) This would define the raw content. It could also be
#   used to point to a template in another module. It might be useful if you
#   want to define the schema as a YAML string.
#
# === Variables
#
# === Examples
#
#     solr::schema { 'myschema.xml':
#       source => 'puppet:///files/mydata/schema.xml',
#     }
#
#
# === Copyright
#
# GPL-3.0+
#
define solr::schema (
  $ensure  = undef,
  $dir     = "${solr::solr_home}/schema",
  $source  = undef,
  $content = undef,
) {

  if ! defined(Class['solr']) {
    fail("You must include the solr base class before using any solr defined\
 resources")
  }

  if (ensure != 'absent') and ($source == undef and $content == undef) {
    fail('solr::schema - You must define either source or content')
  }

  file { "${dir}/${title}":
    ensure  => $ensure,
    owner   => $solr::jetty_user,
    group   => $solr::jetty_group,
    mode    => '0644',
    source  => $source,
    content => $content,
    # For the default parent directory
    require => Package['openvpn'],
  }

}
