#!/bin/bash

# Check for at least one argument
if [ $# -eq 0 ]; then
  echo "Usage: wipsync {add|remove|sync} [...]"
  exit 1
fi

case "$1" in
  add)
    shift # Remove the first argument
    wipsync-add "$@"
    ;;
  remove)
    shift
    wipsync-remove "$@"
    ;;
  sync)
    wipsync-sync
    ;;
  status)
    wipsync-status
    ;;
  *)
    echo "Invalid command. Usage: wipsync {add|remove|sync}"
    exit 1
    ;;
esac
