$PROJ_DIR = "/home/vagrant/HarvardCards"

Exec {
	path => "/usr/local/bin:/usr/bin:/usr/sbin:/sbin:/bin",
}

include init

class init {
	group { "puppet":
		ensure => "present",
	}
	
	exec { "update-apt":
		command => "sudo apt-get update",
	}
	
	package { 'git':
		ensure => latest,
		require => Exec['update-apt'],
	}

	/*
	# get HarvardCards
	exec { 'harvardcards-git':
		command => "git clone https://github.com/Harvard-ATG/HarvardCards.git",
		cwd => "$PROJ_DIR",
		require => Package['git'],
		logoutput => true,
	}
	*/

	# install some dependencies
	package {
		["python", "python-dev", "python-pip"]:
		ensure => installed,
		require => Exec['update-apt']
	}
	
	# install project dependencies
	exec { "pip-install-requirements":
		command => "sudo /usr/bin/pip install -r $PROJ_DIR/requirements.txt",
		tries => 2,
		timeout => 600,
		require => Package['python-pip', 'python-dev'],
		logoutput => true,
	}

	# syncdb
	exec { "syncdb":
		command => "python manage.py syncdb --noinput",
		cwd => "$PROJ_DIR",
		require => Exec['pip-install-requirements'],
		logoutput => true,
	}

	# start server?
	exec { "runserver":
		command => "python manage.py runserver > server.log &",
		cwd => "$PROJ_DIR",
		require => Exec['pip-install-requirements'],
		logoutput => true,	
	}

}