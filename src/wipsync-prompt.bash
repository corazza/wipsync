# wipsync prompt integration
# Source this file from .bashrc to show (*) when tracked repos have uncommitted changes.
# The indicator is read from a file written by the wipsync-daemon, so there is
# zero git overhead per prompt.

__wipsync_prompt() {
    if [ -f "$HOME/.wipsync/prompt_status" ] && [ "$(cat "$HOME/.wipsync/prompt_status" 2>/dev/null)" = "1" ]; then
        __wipsync_indicator="(*) "
    else
        __wipsync_indicator=""
    fi
}

# Append to PROMPT_COMMAND (only once)
if [[ "${PROMPT_COMMAND:-}" != *"__wipsync_prompt"* ]]; then
    PROMPT_COMMAND="__wipsync_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi

# Embed the variable in PS1 (only once).
# Virtual-env activation prepends to PS1, so (venv) will naturally appear
# before (*), giving: (venv) (*) user@host:~$
if [[ "${PS1:-}" != *'${__wipsync_indicator}'* ]]; then
    PS1='${__wipsync_indicator}'"${PS1}"
fi
