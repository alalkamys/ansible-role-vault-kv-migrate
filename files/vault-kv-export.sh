#!/usr/bin/env bash

set -eo pipefail

readonly ARB_TEMP_SECRETS_FILE="arbitrary_temp_secrets.json"
readonly TEMP_SECRETS_FILE="temp_secrets.json"
readonly SECRETS_FILE="secrets.json"

log() {
    local log_type="$1"
    local message="$2"
    local timestamp
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[${log_type}] [${timestamp}] ${message}"
}

log_info() {
    log "INFO" "$1"
}

log_error() {
    log "ERROR" "$1"
    exit 1
}

traverse() {
    local path="$1"
    local result

    local headers=()
    if [[ -n "${CF_TOKEN}" || "${CF_TOKEN}" != "" ]]; then
        headers+=("-header" "cf-access-token=${CF_TOKEN}")
    fi

    result=$(vault kv list -format=json "${headers[@]}" "${path}" 2>&1) || log_error "Failed to list secrets: ${result}"

    while IFS= read -r secret; do
        if [[ "${secret}" == */ ]]; then
            traverse "${path}${secret}"
        else
            local secret_data
            secret_data=$(vault kv get -format=json "${headers[@]}" "${path}${secret}" | jq -r '.data') || log_error "Failed to get secret data: ${secret_data}"

            if [[ "${secret_data}" != "null" ]]; then
                echo "{\"path\":\"${path}${secret}\",\"value\":{\"data\":${secret_data}}}," >>"${ARB_TEMP_SECRETS_FILE}"
            fi
        fi
    done < <(echo "${result}" | jq -r '.[]')
}

main() {
    log_info "Starting secrets retrieval process."

    [[ -f "${ARB_TEMP_SECRETS_FILE}" ]] && rm -f "${ARB_TEMP_SECRETS_FILE}"
    [[ -f "${TEMP_SECRETS_FILE}" ]] && rm -f "${TEMP_SECRETS_FILE}"
    [[ -f "${SECRETS_FILE}" ]] && rm -f "${SECRETS_FILE}"

    if [[ -n "${CF_TOKEN}" || "${CF_TOKEN}" != "" ]]; then
        log_info "CF_TOKEN detected."
    fi

    local vaults
    if [[ "$1" ]]; then
        vaults=("${1%"/"}/")
        log_info "Retrieving all secrets under ${vaults[*]}.."
    else
        local headers=()
        if [[ -n "${CF_TOKEN}" || "${CF_TOKEN}" != "" ]]; then
            headers+=("-header" "cf-access-token=${CF_TOKEN}")
        fi
        log_info "No secret engine provided. Retrieving all secrets.."
        result=$(vault secrets list -format=json "${headers[@]}" 2>&1) || log_error "Failed to list secrets engines: ${result}"
        mapfile -t vaults < <(echo "${result}" | jq -r 'to_entries[] | select(.value.type=="kv") | .key')
    fi

    for vault in "${vaults[@]}"; do
        traverse "${vault}"
    done

    echo "[" >"${TEMP_SECRETS_FILE}"
    sed '$s/,$//' "${ARB_TEMP_SECRETS_FILE}" >>"${TEMP_SECRETS_FILE}"
    echo "]" >>"${TEMP_SECRETS_FILE}"

    jq . "${TEMP_SECRETS_FILE}" >"${SECRETS_FILE}"
    rm "${ARB_TEMP_SECRETS_FILE}" "${TEMP_SECRETS_FILE}"

    log_info "Secrets retrieval completed and saved to ${SECRETS_FILE}"
}

[[ "$0" == "${BASH_SOURCE[0]}" ]] && main "$@"
