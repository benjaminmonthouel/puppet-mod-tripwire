# Class: tripwire
#
# This module manages tripwire
#
# Parameters: tw_site_passphrase, tw_local_passphrase, tw_init, tw_update
#
# Actions:
#
# Requires: None
#
#
class tripwire ( $tw_site_passphrase, $tw_local_passphrase, $tw_init = false, $tw_update = false ) {

  package { 'tripwire': ensure => installed }

  exec { 'tripwire_clean':
    command     => '/bin/rm -f /etc/tripwire/*',
    refreshonly => true,
    subscribe   => Package['tripwire'],
  }

  file { '/etc/tripwire/twcfg.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("tripwire/default/etc/tripwire/twcfg.txt.$operatingsystem.erb"),
    require => Exec['tripwire_clean'],
  }

  file { '/etc/tripwire/twpol.txt':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template("tripwire/default/etc/tripwire/twpol.txt.$operatingsystem.erb"),
    require => Exec['tripwire_clean'],
  }

  exec { 'tripwire_create_local_key':
    command     => "/usr/sbin/twadmin -m G -L /etc/tripwire/${hostname}-local.key -P ${tw_local_passphrase}",
    refreshonly => true,
    creates     => "/etc/tripwire/${hostname}-local.key",
    subscribe   => Exec['tripwire_clean'],
    logoutput   => true,
  }
  
  file { "/etc/tripwire/${hostname}-local.key":
    ensure  => present,
    require => Exec['tripwire_create_local_key'],
  }

  exec { 'tripwire_create_site_key':
    command     => "/usr/sbin/twadmin -m G -S /etc/tripwire/site.key -Q ${tw_site_passphrase}",
    refreshonly => true,
    creates     => '/etc/tripwire/site.key',
    subscribe   => Exec['tripwire_clean'],
  }
 
  file { '/etc/tripwire/site.key':
    ensure  => present,
    require => Exec['tripwire_create_site_key'],
  }
 
  exec { 'tripwire_create_config':
    command     => "/usr/sbin/twadmin -m F -c /etc/tripwire/tw.cfg -S /etc/tripwire/site.key -Q ${tw_site_passphrase} /etc/tripwire/twcfg.txt",
    creates     => '/etc/tripwire/tw.cfg',
    refreshonly => true,
    subscribe   => File['/etc/tripwire/twcfg.txt'],
    require     => [ File["/etc/tripwire/${hostname}-local.key"], File['/etc/tripwire/site.key'] ],
    logoutput   => true,
  }

  file { '/etc/tripwire/tw.cfg':
    ensure  => present,
    require => Exec['tripwire_create_config'],
  }

  exec { 'tripwire_create_policy':
    command     => "/usr/sbin/twadmin -m P -p /etc/tripwire/tw.pol -S /etc/tripwire/site.key -Q ${tw_site_passphrase} /etc/tripwire/twpol.txt",
    creates     => '/etc/tripwire/tw.pol',
    refreshonly => true,
    subscribe   => File['/etc/tripwire/twpol.txt'],
    require     => [ File['/etc/tripwire/tw.cfg'], File['/etc/tripwire/site.key'] ],
  }
  
  file { '/etc/tripwire/tw.pol':
    ensure  => present,
    require => Exec['tripwire_create_policy'],
  }
  
  if $tw_init == true {
    exec { 'tripwire_initialization':
      command     => '/usr/sbin/tripwire -m i',
      creates     => "/var/lib/tripwire/${hostname}.twd",
      logoutput   => true,
    }
  }

  if $tw_update == true {
    exec { 'tripwire_update':
      command     => '/usr/sbin/tripwire -m u',
      creates     => "/var/lib/tripwire/${hostname}.twd",
      logoutput   => true,
    }
  }

}
