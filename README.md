# tripwire #

This module helps install the tripwire(tm) file integrity checker.

Compatibility : Debian Wheezy, Ubuntu Precise

Sample usage :
class { 'tripwire':
  tw_site_passphrase  => "sitePassphrase",
  tw_local_passphrase => "localPassphrase",
}
