start_unit() {
    UNIT=$1

    if run_unit; then
        echo "==> CONFIGURING $1"
    fi
}

finish_unit() {
    if run_unit; then
        echo "[$UNIT] Configured"
    fi
}

run_unit() {
    [-z "$RUN_UNIT"] || ["$RUN_UNIT" == "$UNIT"]
}

run_step() {
    run_unit && ([-z "$RUN_STEP"] || ["$RUN_STEP" == "$STEP"])
}

step() {
    STEP=$1
    DESC=$2
    if run_step; then
        if [ -z "$DESC" ]; then
            echo "[$UNIT] [$STEP] Running step..."
        else
            echo "[$UNIT] [$STEP] $DESC..."
        fi
    fi
} #one or more steps make a unit

ssh_as() {
    if run_step; then
        local args="$1@$SERVER -p $PORT $SSH_OPTIONS"
        shift
        if ["$VERBOSE" = "true"]; then
            ssh $args $@ && success || fail
        else
            ssh $args $@ >/dev/null && success || fail
        fi
    else
        return 0
    fi
}

success() {
    if run_step; then
        print_result "Ok."
    fi
}

fail() {
    if run_step; then
        if [ -z "$1" ]; then
            print_result "^^^ Failed."
        else
            print_result "Failed: $1"
        fi
        exit 1
    fi
}

print_result() {
    if [ -z "$UNIT" ] || [ -z "$STEP" ]; then
        echo $1
    else
        echo "[$UNIT] [$STEP] $1"
    fi
}

capture_ssh_as() {
    if run_step; then
        local args = "$1@$SERVER -p $PORT $SSH_OPTIONS"
        shift
        ssh $args $@ 2>&1
    else
        return 0
    fi
}

scp_as() {
    if run_step; then
        local args="-P $PORT $SSH_OPTIONS"
        if [ "$VERBOSE" = "true" ]; then
            scp $args $2 $1@$SERVER:$3 &&
                success || fail
        else
            scp $args $2 $1@$SERVER:$3 \
                >/dev/null && success || fail
        fi
    else
        return 0
    fi
}

scp_config_as() {
    local dest=$3
    if [ -z "$dest" ]; then
        dest=$2
    fi
    scp_as $1 $DIR/config/$2 $dest
}

ask_password() {
    if run_step; then
        read -sp "Enter passcode for $1: " $2
        echo
    else
        return 0
    fi
}
