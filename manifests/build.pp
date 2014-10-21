
# Postgresql
# https://github.com/puppetlabs/puppetlabs-postgresql

# global pPostgreSQL settings
class { 'postgresql::globals':
  encoding => 'UTF8',
  locale   => 'cs_CZ.UTF-8',
  #version  => '9.3', 
}

class { 'postgresql::server': 
  listen_addresses           => '*',
  postgres_password          => 'postgrespassword',
  
  # https://docs.puppetlabs.com/puppet/latest/reference/lang_relationships.html
  require => Class['postgresql::globals'],
}

# create db + user
postgresql::server::db { 'testdb':
  user     => 'testuser',
  password => postgresql_password('testuser', 'testpassword'),
}

# rule for remote connections
postgresql::server::pg_hba_rule { 'allow remote connections with password':
  type        => 'host',
  database    => 'all',
  user        => 'all',
  address     => 'all',
  auth_method => 'md5',
}

# PostgreSQL password
# http://www.puppetcookbook.com/posts/creating-a-directory.html
file {'.pgpass-vagrant':
  path    => '/home/vagrant/.pgpass',
  ensure  => present,
  mode    => 0600,
  content => "localhost:5432:testdb:testuser:testpassword",
  owner  => "vagrant",
  group  => "vagrant",
}

# initialize the content of your new database
exec { "populate_postgresql":
  command => "/usr/bin/psql -d testdb -U testuser -h localhost -p 5432 --no-password < /vagrant/psql-db/psql-dump.sql",
  path    => "/usr/vagrant/", # tam je .pgpass
  user    => 'vagrant',
  logoutput => true,
  
  
  require => [ File['.pgpass-vagrant'], 
                Postgresql::Server::Db['testdb'], 
                Postgresql::Server::Pg_hba_rule['allow remote connections with password'] ]
}