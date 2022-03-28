epoch() {
    DATE_CMD=date
    if type gdate &>/dev/null; then
        DATE_CMD=gdate
    fi

    $DATE_CMD --date="$1" -u +"%s"
}