# == Type: solr::core
#
# Sets up a core based on the example core installed by default.
#
# === Parameters
#
# [*schema_src_file*]
#   The schema file must exist on the file system and should be controlled
#   outside of this module.  This will simply link the schema file to the
#   new core conf.
#
# [*core_name*]
#   The name of the core (must be unique).
#   Default: $title
#
# === Variables
#
# === Examples
#
# === Copyright
#
# GPL-3.0+
#
define solr::core (
  $schema_src_file = '',
  $core_name = $title,
  ){

  anchor {"solr::core::${core_name}::begin":}

  # The base class must be included first because core uses variables from
  # base class
  if ! defined(Class['solr']) {
    fail("You must include the solr base class before using any solr defined\
 resources")
  }

  $dest_dir    = "${solr::solr_home}/solr/${core_name}"
  $schema_file = "${dest_dir}/conf/schema.xml"

  exec {"${core_name}_copy_core":
    command => "/bin/cp -r ${solr::solr_home_example_dir} ${dest_dir} &&\
 /bin/chown -R ${solr::jetty_user}:${solr::jetty_user} ${dest_dir}",
    creates => $dest_dir,
    require => Anchor["solr::core::${core_name}::begin"],
  }

  if $schema_src_file {
    file {$schema_file:
      ensure  => link,
      target  => $schema_src_file,
      require => Exec ["${core_name}_copy_core"],
    }
  } else {
    file {$schema_file:
      ensure  => file,
      # only here to keep require happy
      require => Exec ["${core_name}_copy_core"],
    }
  }


  file {"${dest_dir}/core.properties":
    ensure  => file,
    content => inline_template("name=${core_name}\n"),
    require => File[$schema_file],
  }

  anchor {"solr::core::${core_name}::end":
    require => File ["${dest_dir}/core.properties"],
  }
}
