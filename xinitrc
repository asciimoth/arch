eval $(dbus-launch --sh-syntax --exit-with-session)
yubikey-touch-detector -libnotify &
xset s off -dpms
exec awesome
