#!/bin/bash

# Default to status if no arguments are provided
if [ $# -eq 0 ]; then
  wipsync-status
  exit 0
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
    echo "Invalid command. Usage: wipsync {add|remove|status|sync}"
    exit 1
    ;;
esac
