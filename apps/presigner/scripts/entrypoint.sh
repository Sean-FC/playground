#!/usr/bin/env bash
set -e

export PYTHON_GIL=1 # Keep on currently, need an experimental container fork

# For appropriate worker number calculation
get_worker_count() {
  n_cores=$(($(nproc) / 8)) # Default to 1/8 of the available cores
  if [[ -f /sys/fs/cgroup/cpu.max ]]; then # cgroup v2, i.e. likely local docker
    read -r quota period < /sys/fs/cgroup/cpu.max
    if [[ "$quota" != "max" && -n "$quota" && -n "$period" ]]; then
      n_cores=$(awk "BEGIN { print $quota / $period }")
    fi
  elif [[ -f /sys/fs/cgroup/cpu/cpu.cfs_quota_us ]]; then # cgroup v1, i.e. k8s
    quota=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
    period=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
    if [[ "$quota" -gt 0 && -n "$period" ]]; then
      n_cores=$(awk "BEGIN { print $quota / $period }")
    fi
  fi
  # Uvicorn recommendation: https://docs.gunicorn.org/en/stable/design.html#how-many-workers
  echo "$(awk "BEGIN { print int(2 * $n_cores + 1 + 0.5) }")"
}

if [ -z "$WEB_CONCURRENCY" ]; then
  echo "WEB_CONCURRENCY not set, inferring number of workers."
  WEB_CONCURRENCY=$(get_worker_count)
fi
echo "Starting server with $WEB_CONCURRENCY workers..."
if [ "$WEB_CONCURRENCY" -gt 1 ]; then
  export PROMETHEUS_MULTIPROC_DIR="${PROMETHEUS_MULTIPROC_DIR:-$(mktemp -d)}"
  echo "Set PROMETHEUS_MULTIPROC_DIR: $PROMETHEUS_MULTIPROC_DIR"
else
  echo "Unsetting PROMETHEUS_MULTIPROC_DIR, only one worker."
  unset PROMETHEUS_MULTIPROC_DIR
fi
exec python -m uvicorn presigner.main:app --host 0.0.0.0 --port "${PORT:-80}" --workers "$WEB_CONCURRENCY"
