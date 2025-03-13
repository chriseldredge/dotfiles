deactivate-assumed-role() {
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
}

assume-role() {
    local ROLE=""
    local SESSION_NAME="cveld-local-dev"
    local POLICY=""
    local EXPORT_VARS=false
    local PRINT_VARS=false
    local DEACTIVATE_FIRST=false
    local VERBOSE=false

    # Parse named arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --session-name)
                SESSION_NAME="$2"
                shift 2
                ;;
            --policy)
                POLICY="$2"
                shift 2
                ;;
            --deactivate-first)
                DEACTIVATE_FIRST=true
                shift
                ;;
            --export)
                EXPORT_VARS=true
                shift
                ;;
            --print)
                PRINT_VARS=true
                shift
                ;;
            --verbose)
                VERBOSE=true
                shift
                ;;
            *)
                # First non-flag argument is the role ARN or name
                if [[ -z "$ROLE_ARN" ]]; then
                    ROLE="$1"
                else
                    echo "Unexpected argument: $1" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done

    if [[ -z "$ROLE" ]]; then
        echo "Error: Role ARN or name is required" >&2
        return 1
    fi

    if $DEACTIVATE_FIRST; then
        deactivate-assumed-role
    fi

    local ROLE_ARN

    if [[ "$ROLE" != $'arn:'* ]]; then
        ROLE_ARNS=$(aws iam list-roles | jq -r '.Roles[] | select(.RoleName | contains("'$ROLE'")).Arn')
        local N=$(echo -en $ROLE | wc -l | tr -d ' ')

        if [ -z "$ROLE_ARNS" ]; then
            echo "No role found matching ${ROLE}" >&2
            return 1
        elif ((N>1)); then
            echo "Found $N roles matching ${ROLE}:\n$ROLE_ARNS" >&2
            return 1
        fi

        ROLE_ARN=${ROLE_ARNS}
    else
        ROLE_ARN=ROLE
    fi

    if $VERBOSE; then
        echo Assuming role $ROLE_ARN with session name $SESSION_NAME
    fi

    local ARGS=("sts" "assume-role" "--role-arn" "$ROLE_ARN" "--role-session-name" "$SESSION_NAME" "--output" "json")

    if [[ -n "${POLICY}" ]]; then
        ARGS+="--policy"
        ARGS+="${POLICY}"
    fi

    if $VERBOSE; then
        echo aws "${ARGS[@]}"
    fi

    local ROLE_JSON=$(aws "${ARGS[@]}")
    local RES=$?
    if ((RES!=0)); then
        return $RES
    fi

    local LOCAL_AWS_ACCESS_KEY_ID=$(echo $ROLE_JSON | jq -r '.Credentials''.AccessKeyId')
    local LOCAL_AWS_SECRET_ACCESS_KEY=$(echo $ROLE_JSON | jq -r '.Credentials''.SecretAccessKey')
    local LOCAL_AWS_SESSION_TOKEN=$(echo $ROLE_JSON | jq -r '.Credentials''.SessionToken')

    if $EXPORT_VARS; then
        echo "export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
        export AWS_ACCESS_KEY_ID=$LOCAL_AWS_ACCESS_KEY_ID \
           AWS_SECRET_ACCESS_KEY=$LOCAL_AWS_SECRET_ACCESS_KEY \
           AWS_SESSION_TOKEN=$LOCAL_AWS_SESSION_TOKEN
    fi

    if $PRINT_VARS; then
        echo "AWS_ACCESS_KEY_ID=\"${LOCAL_AWS_ACCESS_KEY_ID}\""
        echo "AWS_SECRET_ACCESS_KEY=\"${LOCAL_AWS_SECRET_ACCESS_KEY}\""
        echo "AWS_SESSION_TOKEN=\"${LOCAL_AWS_SESSION_TOKEN}\""
    fi
}
