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

	# install some dependencies
	package {
		["python", "python-dev", "python-pip", "python-setuptools"]:
		ensure => installed,
		require => Exec['update-apt']
	}
}

class djangoapp {
	$PROJ_DIR = "/home/vagrant/HarvardCards"
	$GIT_CLONE_URL = "https://github.com/Harvard-ATG/HarvardCards.git"

	# install dependencies needed for Pillow (python imaging module)
	# https://pypi.python.org/pypi/Pillow/
	# http://pillow.readthedocs.org/
	package { 
		['libtiff4-dev', 'libjpeg8-dev', 'zlib1g-dev',  'libfreetype6-dev', 'liblcms2-dev', 'tcl8.5-dev', 'tk8.5-dev', 'python-tk']:
		ensure => installed,
		require => Exec['update-apt']
	}

	# get application from git
	exec { 'git-clone':
		command => "git clone $GIT_CLONE_URL $PROJ_DIR",
		require => Package['git'],
		onlyif => ["test ! -d $PROJ_DIR/.git"],
		logoutput => true,
	}

	# install project dependencies
	exec { "pip-install-requirements":
		command => "sudo /usr/bin/pip install -r $PROJ_DIR/requirements.txt",
		tries => 2,
		timeout => 600,
		require => [Package['python-pip', 'python-dev'],Exec['git-clone']],
		logoutput => true,
	}

	# syncdb
	exec { "django-syncdb":
		command => "python manage.py syncdb --noinput",
		cwd => "$PROJ_DIR",
		require => Exec['pip-install-requirements'],
		logoutput => true,
	}

	# setup super user
	exec { "django-setup-superuser":
		command => 'echo "from django.contrib.auth.models import User; User.objects.create_superuser(\'admin\', \'admin@example.com\', \'admin\')" | ./manage.py shell',
		cwd => "$PROJ_DIR",
		require => Exec['django-syncdb']
	}

	# start server?
	exec { "django-runserver":
		command => "python manage.py runserver 0.0.0.0:8000 > server.log &",
		cwd => "$PROJ_DIR",
		require => Exec['django-syncdb'],
		logoutput => true,	
	}
}

include djangoapp
