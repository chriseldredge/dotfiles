deactivate-assumed-role() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}

assume-role() {
    ROLE_ARN=$1
    SESSION_NAME="${2:-cveld-local-dev}"
    POLICY="${3}"

    deactivate-assumed-role

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

    ARGS=("sts" "assume-role" "--role-arn" "$ROLE_ARN" "--role-session-name" "$SESSION_NAME" "--output" "json")

    if [[ -n "${POLICY}" ]]; then
        ARGS+="--policy"
        ARGS+="${POLICY}"
    fi

    echo aws "${ARGS[@]}"
    ROLE_JSON=$(aws "${ARGS[@]}")
    RES=$?
    if ((RES!=0)); then
        return $RES
    fi

    export AWS_ACCESS_KEY_ID=$(echo $ROLE_JSON | jq -r '.Credentials''.AccessKeyId')
    export AWS_SECRET_ACCESS_KEY=$(echo $ROLE_JSON | jq -r '.Credentials''.SecretAccessKey')
    export AWS_SESSION_TOKEN=$(echo $ROLE_JSON | jq -r '.Credentials''.SessionToken')
}
