define yumwrapper (
  $ensure = 'present',
  $enablerepo = undef,
  $urlrepokey = undef,
  $urlrepo = undef,
  ) {
  if $enablerepo {
    case $ensure {
      'present', 'installed': {

        $repo_present = "repo_install_${enablerepo}_4_${name}"
        exec { $repo_present:
          command => "rpm --import ${urlrepokey} ; rpm -Uv ${urlrepo}",
          unless => "yum repolist | grep ${enablerepo}",
          path => ['/usr/bin', '/bin'],
          logoutput => on_failure,
        }

        $yum_name = "yum_install_${name}"
        exec { $yum_name:
          command => "yum install -y --enablerepo=${enablerepo} ${name}",
          unless => "rpm -q ${name}",
          path => ['/usr/bin', '/bin'],
          logoutput => on_failure,
          require => Exec[$repo_present],
        }

        # Create a package resource, this effectively does nothing but create
        # a graph node for the package that was manually installed above.
        package { $name:
          ensure => present,
          require => Exec[$yum_name],
        }
      }
      'absent': {
        package { $name:
          ensure => 'absent',
        }
      }
      default: {
        fail("Only present, installed or absent is accepted")
      }
    }
  } else {
    package { $name:
      ensure => $ensure,
      provider => 'yum',
    }
  }
}
