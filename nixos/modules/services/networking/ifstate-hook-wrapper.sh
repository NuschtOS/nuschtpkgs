unit_name() {
  name="ifstate-hook-@hookName@"

  if [[ "$IFS_NETNS" -ne "" ]]; then
    name="$name-$IFS_NETNS"
  fi

  if [[ "$IFS_VRF" -ne "" ]]; then
    name="$name-$IFS_VRF"
  fi

  systemd-escape "$name"
}

start() {
    unit=$(unit_name)

    if systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_OK"
    fi

    description="IfState Hook"

    args=(
      '--quiet'
      '--no-block'
      "--unit=$unit"
      "--setenv=IFS_IFNAME=$IFS_IFNAME"
      "--setenv=IFS_INDEX=$IFS_INDEX"
      "--setenv=IFS_NETNS=$IFS_NETNS"
      "--setenv=IFS_VRF=$IFS_VRF"
    )

    for var in "${!IFS_ARG_@}"; do
      args+=("--setenv=$var=${!var}")
    done

    if [[ -n "$IFS_NETNS" ]]; then
      args+=("--property=NetworkNamespacePath=/var/netns/$IFS_NETNS")
      description="$description Netns $IFS_NETNS"
    fi

    if [[ -n "$IFS_VRF" ]]; then
      args+=("--property=BindNetworkInterface=$IFS_VRF")
      description="$description Vrf $IFS_VRF"
    fi

    args+=("--description=$description @hookDescription@")
    args+=(@systemdRunArgs@)

    systemd-run "${args[@]}"

    exit "$IFS_RC_STARTED"
}

stop() {
    unit=$(unit_name)

    if ! systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_OK"
    fi

    systemctl stop --quiet "$unit"
    exit "$IFS_RC_STOPPED"
}

check_start() {
    unit=$(unit_name)
    if systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_OK"
    fi
    exit "$IFS_RC_CHANGED"
}

check_stop() {
    unit=$(unit_name)
    if systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_CHANGED"
    fi
    exit "$IFS_RC_OK"
}

case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    check-start)
        check_start
        ;;
    check-stop)
        check_stop
        ;;
    *)
        echo "usage: $0 {start|check-start|stop|check-stop}"
        exit 1
        ;;
esac
