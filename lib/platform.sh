# shellcheck shell=bash
# ============================================================
# lib/platform.sh — OS / arch / distro / package-manager detection
# ============================================================
# Everything is detected once by detect_platform and exposed as globals:
#   OS          macos | linux
#   ARCH        x86_64 | arm64 | armv7 | <raw uname -m>
#   DISTRO_ID   os-release ID (e.g. ubuntu, fedora, arch)
#   DISTRO_LIKE os-release ID_LIKE (e.g. "debian", "rhel fedora")
#   PKG_MGR     brew | apt | dnf | yum | pacman | zypper | apk | xbps | none
#   LIBC        glibc | musl (Linux only)
#   IS_WSL      true | false
#
# Package-manager detection probes for the binary rather than matching
# distro names, so derivatives (Zorin, Nobara, CachyOS, Artix, …) work
# without being listed anywhere.

_os_release() {
  [[ -r /etc/os-release ]] || return 0
  # shellcheck disable=SC1091
  (. /etc/os-release && eval "printf '%s' \"\${$1:-}\"")
}

detect_platform() {
  case "$(uname -s)" in
  Darwin) OS=macos ;;
  Linux) OS=linux ;;
  *) OS=unknown ;;
  esac

  case "$(uname -m)" in
  x86_64 | amd64) ARCH=x86_64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  armv7* | armv6*) ARCH=armv7 ;;
  *) ARCH=$(uname -m) ;;
  esac

  DISTRO_ID="" DISTRO_LIKE="" DISTRO_VERSION="" LIBC="" IS_WSL=false

  if [[ "$OS" == "macos" ]]; then
    DISTRO_ID=macos
    DISTRO_VERSION=$(sw_vers -productVersion 2>/dev/null)
    PKG_MGR=none
    _load_brew && PKG_MGR=brew
    return 0
  fi

  DISTRO_ID=$(_os_release ID)
  DISTRO_LIKE=$(_os_release ID_LIKE)
  DISTRO_VERSION=$(_os_release VERSION_ID)
  : "${DISTRO_ID:=unknown}"

  if ldd --version 2>&1 | grep -qi musl || ls /lib/ld-musl-* >/dev/null 2>&1; then
    LIBC=musl
  else
    LIBC=glibc
  fi

  grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=true

  PKG_MGR=none
  local candidate
  for candidate in apt-get:apt dnf:dnf yum:yum pacman:pacman zypper:zypper apk:apk xbps-install:xbps; do
    if check_command "${candidate%%:*}"; then
      PKG_MGR="${candidate##*:}"
      break
    fi
  done
}

# Homebrew isn't always on PATH in non-login shells (esp. Apple Silicon).
_load_brew() {
  local prefix
  for prefix in /opt/homebrew /usr/local /home/linuxbrew/.linuxbrew; do
    if [[ -x "$prefix/bin/brew" ]]; then
      eval "$("$prefix/bin/brew" shellenv)"
      return 0
    fi
  done
  check_command brew
}

# distro_is <id>... — matches ID or any ID_LIKE entry
distro_is() {
  local want word
  for want in "$@"; do
    [[ "$DISTRO_ID" == "$want" ]] && return 0
    for word in $DISTRO_LIKE; do
      [[ "$word" == "$want" ]] && return 0
    done
  done
  return 1
}

platform_summary() {
  if [[ "$OS" == "macos" ]]; then
    printf 'macOS %s · %s · %s' "$DISTRO_VERSION" "$ARCH" "$PKG_MGR"
  else
    printf '%s %s · %s · %s · %s' "$DISTRO_ID" "$DISTRO_VERSION" "$ARCH" "$LIBC" "$PKG_MGR"
    [[ "$IS_WSL" == "true" ]] && printf ' · WSL'
  fi
  return 0
}
