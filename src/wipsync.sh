#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: wipsync {add|remove|status}"
    echo ""
    echo "Commands:"
    echo "  add <dir>     Add a directory to track for git repositories"
    echo "  remove <dir>  Remove a directory from tracking"
    echo "  status        Show status of all tracked repositories (default)"
    echo ""
    echo "Status markers:"
    echo "  (*)   Uncommitted changes"
    echo "  (^)   Unpushed commits"
    echo "  (*^)  Both uncommitted changes and unpushed commits"
}

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
  status)
    wipsync-status
    ;;
  -h|--help)
    usage
    ;;
  *)
    echo "Invalid command: $1"
    usage
    exit 1
    ;;
esac
