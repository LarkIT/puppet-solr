# == Type: solr::core
#
# Sets up a core based on the example core installed by default.
#
# === Parameters
#
# [*schema_src_file*]
#   The schema file must exist on the file system and may be controlled
#   outside of this module. You may also use solr::schema to create the
#   schema file. If it starts with a "/" it is assumed that it is a full
#   path, otherwise it is assumed that it is within (solr_home)/schema/.
#   This will simply link the schema file to the new core conf dir.
#
# [*conf_dir_source*]
#   file "source" entry to a "conf" directory to be loaded into the schema.
#   If this is not specified, the default "collection1" config will be copied.
#   Default: undef
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
  $schema_src_file = undef,
  $conf_dir_source = undef,
  $core_name = $title,
  ){

  anchor {"solr::core::${core_name}::begin":
    require => Anchor ["solr::install::end"]
  }

  # The base class must be included first because core uses variables from
  # base class
  if ! defined(Class['solr']) {
    fail("You must include the solr base class before using any solr defined\
 resources")
  }

  if $schema_src_file and $conf_dir {
    notice("solr::core: schema_src_file: ${schema_src_file} and conf_dir: ${conf_dir} both defined. This may not be what you intended.")
  }

  $dest_dir    = "${solr::solr_home}/solr/${core_name}"
  $conf_dir    = "${dest_dir}/conf"
  $schema_file = "${conf_dir}/schema.xml"


  if $conf_dir_source {

    file { "${dest_dir}":
      ensure  => directory,
      owner   => $solr::jetty_user,
      group   => $solr::jetty_group,
      require => Anchor["solr::core::${core_name}::begin"],
    }

    file { "${conf_dir}":
      ensure  => directory,
      source  => $conf_dir_source,
      owner   => $solr::jetty_user,
      group   => $solr::jetty_group,
      recurse => true,
      purge   => true,
    }

  } else {

    exec {"${core_name}_copy_core":
      command => "/bin/cp -r ${solr::solr_home_example_dir} ${dest_dir} &&\
   /bin/chown -R ${solr::jetty_user}:${solr::jetty_user} ${dest_dir}",
      creates => $dest_dir,
      require => Anchor["solr::core::${core_name}::begin"],
    }

    # Keeping these to reduce the number of "requires"
    file { ["${dest_dir}", "${conf_dir}"]:
      ensure  => directory,
      owner   => $solr::jetty_user,
      group   => $solr::jetty_group,
      require => Exec ["${core_name}_copy_core"],
    }

  }

  # Symlink schema (optional)
  if $schema_src_file {
    if $schema_src_file =~ /^\// {
      $_schema_src_file = $schema_src_file
    } else {
      $_schema_src_file = "${solr::solr_home}/schema/${schema_src_file}"
    }
    file {$schema_file:
      ensure  => link,
      target  => $_schema_src_file,
    }
  }

  # Set corename
  file {"${dest_dir}/core.properties":
    ensure  => file,
    content => inline_template("name=${core_name}\n"),
  }

  if versioncmp($solr::version, '4.4.0') < 0 {
    # VERY old Solr needs solr.xml to contain cores
    concat_fragment {"solr.xml-${core_name}":
      target  => "${solr::solr_home}/solr/solr.xml",
      content => "     <core name=\"${core_name}\" instanceDir=\"${core_name}\" />",
      order   => '10',
    }
  }

  anchor {"solr::core::${core_name}::end":
    require => File ["${dest_dir}/core.properties"],
  }
}
