unit_name() {
  local name="ifstate-hook-@hookName@"

  if [[ "$IFS_NETNS" != "" ]]; then
    name="$name-$IFS_NETNS"
  fi

  if [[ "$IFS_VRF" != "" ]]; then
    name="$name-$IFS_VRF"
  fi

  systemd-escape "$name"
}

start() {
    local unit
    unit=$(unit_name)

    if systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_OK"
    fi

    local description="IfState Hook"

    local args=(
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
      args+=("--property=NetworkNamespacePath=/var/run/netns/$IFS_NETNS")
      description="$description Netns $IFS_NETNS"
    fi

    if [[ -n "$IFS_VRF" ]]; then
      args+=("--property=BindNetworkInterface=$IFS_VRF")
      description="$description Vrf $IFS_VRF"
    fi

    args+=("--description=$description @hookDescription@")
    args+=(@systemdRunArgs@)

    if systemd-run "${args[@]}"; then
      exit "$IFS_RC_STARTED"
    else
      exit "$IFS_RC_ERROR"
    fi
}

stop() {
    local unit
    unit=$(unit_name)

    if ! systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_OK"
    fi

    systemctl stop --quiet "$unit"
    exit "$IFS_RC_STOPPED"
}

check_start() {
    local unit
    unit=$(unit_name)

    if systemctl is-active --quiet "$unit"; then
        exit "$IFS_RC_OK"
    fi

    exit "$IFS_RC_CHANGED"
}

check_stop() {
    local unit
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
