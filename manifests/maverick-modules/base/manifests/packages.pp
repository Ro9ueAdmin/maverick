class base::packages {

    # Remove large packages that come with raspbian as otherwise we don't have enough space to continue
    package { "sonic-pi":
	    ensure		=> purged
    }
    
    # Remove some stuff that definitely doesn't belong in a robotics build
    package { ["kodi", "kodi-bin", "kodi-data", "libreoffice", "ubuntu-mate-libreoffice-draw-icons", "libreoffice-base-core", "libreoffice-common", "libreoffice-core"]:
        ensure      => purged
    }

    # These packages are installed by default for all installs.  
    # Be careful of what is put here, usually packages should be put in more specific manifests
    ensure_packages([
        "telnet",
        "iotop",
        "build-essential",
        "xz-utils",
        "unzip",
        "wget",
        "curl",
        "ncurses-bin",
        "bsdmainutils",
        "v4l-utils",
        "cmake",
        "pkg-config",
        "usbutils",
        "lsof",
        "tcpdump",
        "whois",
    ])

    if $operatingsystem == "Ubuntu" {
        ensure_packages(["linux-firmware"])
    } elsif $operatingsystem == "Debian" {
        ensure_packages(["firmware-linux", "firmware-atheros", "firmware-brcm80211", "firmware-ralink", "firmware-realtek"])
    }
    
    # These packages should be removed from all installs.  
    # Usually these are included in the default OS build and are not necessary, or cause some conflict or unwanted behaviour
    # We have to list them independently because putting them in a package [] doesn't seem to deal with dependencies
    if ($operatingsystem == "CentOS") or ($operatingsystem == "Fedora") or ($operatingsystem == "RedHat") {
        package { "fprintd-pam": ensure => absent } ->
        package { "fprintd": ensure => absent } ->
        package { "libfprint": ensure => absent } 
    }

    # Remove upstart as it breaks ubuntu which is now systemd
    # This is done in maverick shell script but make sure here
    #package { ["upstart", "unity-greeter"]:
	#    ensure		=> purged
    #}

    # Remove ModeManager which conflicts with APM/Pixhawk
    package { "modemmanager":
        ensure      => purged
    }
    
    # Install python using python module
    class { "python":
        version    => 'system',
        pip        => 'present',
        dev        => 'present',
        virtualenv => 'present',
        gunicorn   => 'absent',
    } ->
    package { ["python-setuptools", "virtualenvwrapper", "python-numpy", "python3-numpy", "python-lockfile", "python-daemon"]:
        ensure      => present
    } ->
    # Install PyRIC and netifaces, python modules necessary to run maverick --netinfo
    # Python::pip doesn't seem to work here, use exec instead
    exec { "install-pyric":
        command     => "/usr/bin/pip install PyRIC",
        unless      => "/usr/bin/pip list |grep PyRIC",
        require     => [ Class["python"], Class["locales"] ]
    } ->
    exec { "install-netifaces":
        command     => "/usr/bin/pip install netifaces",
        unless      => "/usr/bin/pip list |grep netifaces",
        require     => [ Class["python"], Class["locales"] ]
    } ->
    # Install python future, important base module for python 2.7
    exec { "install-pyfuture":
        command     => "/usr/bin/pip install future",
        unless      => "/usr/bin/pip list |grep future",
        require     => [ Class["python"], Class["locales"] ]
    }

}
