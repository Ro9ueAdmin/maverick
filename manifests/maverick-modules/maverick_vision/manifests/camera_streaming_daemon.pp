class maverick_vision::camera_streaming_daemon (
    $camera_streaming_daemon_source = "https://github.com/01org/camera-streaming-daemon.git",
    $rtsp_port = 8554,
    $active = false,
) {

    if ! ("install_flag_camera-streaming-daemon" in $installflags) {
        ensure_packages(["libavahi-common-dev", "libavahi-core-dev", "libavahi-glib-dev", "libavahi-client-dev"])
        oncevcsrepo { "git-camera-streaming-daemon":
            gitsource   => $camera_streaming_daemon_source,
            dest        => "/srv/maverick/var/build/camera-streaming-daemon",
            submodules  => true,
        } ->
        exec { "camera-streaming-daemon-build":
            user        => "mav",
            timeout     => 0,
            environment => ["PKG_CONFIG_PATH=/srv/maverick/software/gstreamer/lib/pkgconfig"],
            command     => "/srv/maverick/var/build/camera-streaming-daemon/autogen.sh && CFLAGS='-g -O2' /srv/maverick/var/build/camera-streaming-daemon/configure --prefix=/srv/maverick/software/camera-streaming-daemon && /usr/bin/make -j${::processorcount} && make install >/srv/maverick/var/log/build/camera-streaming-daemon.build.out 2>&1",
            cwd         => "/srv/maverick/var/build/camera-streaming-daemon",
            creates     => "/srv/maverick/software/camera-streaming-daemon/bin/camera-streaming-daemon",
            require     => Package["libavahi-common-dev"],
        } ->
        file { "/srv/maverick/var/build/.install_flag_camera-streaming-daemon":
            ensure      => file,
            owner       => "mav",
        }
    }
    file { "/etc/systemd/system/maverick-camera-streaming-daemon.service":
        source      => "puppet:///modules/maverick_vision/camera-streaming-daemon.service",
        owner       => "root",
        group       => "root",
        mode        => 644,
        notify      => Exec["maverick-systemctl-daemon-reload"],
    }
    
    # Punch some holes in the firewall for rtsp
    if defined(Class["::maverick_security"]) {
        maverick_security::firewall::firerule { "vision-rtsp-udp":
            ports       => [$rtsp_port],
            ips         => hiera("all_ips"),
            proto       => "udp", # allow both tcp and udp for rtsp and rtp
        }
        maverick_security::firewall::firerule { "vision-rtsp-tcp":
            ports       => [$rtsp_port],
            ips         => hiera("all_ips"),
            proto       => "tcp", # allow both tcp and udp for rtsp and rtp
        }
    }
    
    if $active == true {
        service { "maverick-camera-streaming-daemon":
            ensure      => running,
            enable      => true,
        }
    } else {
        service { "maverick-camera-streaming-daemon":
            ensure      => stopped,
            enable      => false,
        }
    }

}