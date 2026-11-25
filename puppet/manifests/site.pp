node 'puppet-agent-1', 'puppet-agent-2' {

  package { 'apache2':
    ensure => installed,
  }

  service { 'apache2':
    ensure  => running,
    enable  => true,
    require => Package['apache2'],
  }

  file { '/var/www/html/index.html':
    ensure  => file,
    content => '<h1>DevOps Automation Project</h1><p>Apache managed by Puppet</p>',
    require => Package['apache2'],
  }

}
