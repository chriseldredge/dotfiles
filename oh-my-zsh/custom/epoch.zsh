epoch() {
    DATE_CMD=date
    if type gdate &>/dev/null; then
        DATE_CMD=gdate
    fi

    local input="$1"
    if [[ -z "$input" || "$input" == "-" ]]; then
        input=$(cat)
    fi

    $DATE_CMD --date="$input" -u +"%s"
}

zulu() {
    DATE_CMD=date
    if type gdate &>/dev/null; then
        DATE_CMD=gdate
    fi

    local input="$1"
    if [[ -z "$input" || "$input" == "-" ]]; then
        input=$(cat)
    fi

    $DATE_CMD --date="@${input}" -u --iso-8601=seconds
}