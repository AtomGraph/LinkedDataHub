#!/bin/sh
# Hands the plugin's userConfig values to the ldh CLI: appends them as exports to the session's
# env file, which Claude Code applies to later Bash commands. Reads nothing else, sends nothing.

[ -n "$CLAUDE_ENV_FILE" ] || exit 0

export_option() {
    [ -n "$2" ] || return 0
    printf "export %s='%s'\n" "$1" "$(printf '%s' "$2" | sed "s/'/'\\\\''/g")" >> "$CLAUDE_ENV_FILE"
}

export_option LDH_BASE "$CLAUDE_PLUGIN_OPTION_LDH_BASE"
export_option LDH_CERT_FILE "$CLAUDE_PLUGIN_OPTION_CERT_FILE"
export_option LDH_CERT_PASSWORD "$CLAUDE_PLUGIN_OPTION_CERT_PASSWORD"
