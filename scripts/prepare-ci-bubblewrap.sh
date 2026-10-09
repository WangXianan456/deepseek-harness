#!/usr/bin/env bash
set -euo pipefail

# Ubuntu's package transaction scans the hosted image's full dpkg database and
# runs post-install hooks. CI needs only a signed-archive payload, so download
# the package directly from the configured APT repository metadata.

: "${RUNNER_TEMP:?prepare-ci-bubblewrap requires RUNNER_TEMP}"
: "${GITHUB_PATH:?prepare-ci-bubblewrap requires GITHUB_PATH}"

if [[ "$(uname -s)" != 'Linux' || "$(uname -m)" != 'x86_64' ]]; then
  echo 'prepare-ci-bubblewrap supports only Linux x86_64 hosted runners' >&2
  exit 1
fi

archive="${RUNNER_TEMP}/bubblewrap_amd64.deb"
download_root="${RUNNER_TEMP}/dsh-bubblewrap-download"
root="${RUNNER_TEMP}/dsh-bubblewrap"

mkdir -p "$download_root"
rm -f "${download_root}"/bubblewrap_*.deb
(
  cd "$download_root"
  apt-get download bubblewrap
)
downloaded_archive="$(find "$download_root" -maxdepth 1 -type f -name 'bubblewrap_*_amd64.deb' -print -quit)"
if [[ -z "$downloaded_archive" ]]; then
  echo 'unable to locate downloaded bubblewrap archive' >&2
  exit 1
fi
cp "$downloaded_archive" "$archive"
mkdir -p "$root"
dpkg-deb --extract "$archive" "$root"
printf '%s\n' "$root/usr/bin" >> "$GITHUB_PATH"

sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0 \
  || echo 'apparmor userns knob absent — the functional probe decides'
"$root/usr/bin/bwrap" --version
"$root/usr/bin/bwrap" --ro-bind / / --dev /dev --unshare-pid --proc /proc --die-with-parent -- true
echo 'bubblewrap functional probe passed'
