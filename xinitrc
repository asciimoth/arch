eval $(dbus-launch --sh-syntax --exit-with-session)
yubikey-touch-detector -libnotify &
exec awesome
