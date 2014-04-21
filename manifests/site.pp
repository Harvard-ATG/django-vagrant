$PROJ_DIR = "/home/vagrant/HarvardCards"
$GIT_CLONE_URL = "https://github.com/Harvard-ATG/HarvardCards.git"

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

	# get application from git
	exec { 'git-app':
		command => "git clone $GIT_CLONE_URL $PROJ_DIR",
		require => Package['git'],
		onlyif => ["test ! -d $PROJ_DIR/.git"],
		logoutput => true,
	}

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
		require => [Package['python-pip', 'python-dev'],Exec['git-app']],
		logoutput => true,
	}

	# syncdb
	exec { "django-syncdb":
		command => "python manage.py syncdb --noinput",
		cwd => "$PROJ_DIR",
		require => Exec['pip-install-requirements'],
		logoutput => true,
	}

	# start server?
	exec { "django-runserver":
		command => "python manage.py runserver 0.0.0.0:8000 2>&1 server.log &",
		cwd => "$PROJ_DIR",
		require => Exec['django-syncdb'],
		logoutput => true,	
	}

}
