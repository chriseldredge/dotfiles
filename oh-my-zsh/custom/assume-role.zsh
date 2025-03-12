deactivate-assumed-role() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}

assume-role() {
    local ROLE_ARN=$1
    local SESSION_NAME="${2:-cveld-local-dev}"
    local POLICY="${3}"

    local EXPORT_VARS=false
    local PRINT_VARS=false
    for arg in "$@"; do
        if [[ "$arg" == "--deactivate-first" ]]; then
            deactivate-assumed-role
        elif [[ "$arg" == "--export" ]]; then
            EXPORT_VARS=true
        elif [[ "$arg" == "--print" ]]; then
            PRINT_VARS=true
        fi
    done

    if [[ "$ROLE_ARN" != $'arn:'* ]]; then
        ROLE_ARN=$(aws iam list-roles | jq -r '.Roles[] | select(.RoleName | contains("'$1'")).Arn')
        N=$(echo -en $ROLE_ARN | wc -l | tr -d ' ')

        if [ -z "$ROLE_ARN" ]; then
            echo "No role found matching $1" >&2
            return 1
        elif ((N>1)); then
            echo "Found $N roles matching $1:\n$ROLE_ARN" >&2
            return 1
        fi
    fi

    echo Assuming role $ROLE_ARN with session name $SESSION_NAME

    local ARGS=("sts" "assume-role" "--role-arn" "$ROLE_ARN" "--role-session-name" "$SESSION_NAME" "--output" "json")

    if [[ -n "${POLICY}" ]]; then
        ARGS+="--policy"
        ARGS+="${POLICY}"
    fi

    echo aws "${ARGS[@]}"
    local ROLE_JSON=$(aws "${ARGS[@]}")
    local RES=$?
    if ((RES!=0)); then
        return $RES
    fi

    local AWS_ACCESS_KEY_ID=$(echo $ROLE_JSON | jq -r '.Credentials''.AccessKeyId')
    local AWS_SECRET_ACCESS_KEY=$(echo $ROLE_JSON | jq -r '.Credentials''.SecretAccessKey')
    local AWS_SESSION_TOKEN=$(echo $ROLE_JSON | jq -r '.Credentials''.SessionToken')

    if $EXPORT_VARS; then
        echo "export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
        export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
    fi

    if $PRINT_VARS; then
        echo "AWS_ACCESS_KEY_ID=\"${AWS_ACCESS_KEY_ID}\""
        echo "AWS_SECRET_ACCESS_KEY=\"${AWS_SECRET_ACCESS_KEY}\""
        echo "AWS_SESSION_TOKEN=\"${AWS_SESSION_TOKEN}\""
    fi
}
