# Formula/mootx01.rb
#
# Homebrew formula for MOOTx01 CE — on-device AI memory substrate.
# Tap: codedaptive/mootx01-ce
#
# Install:
#   brew install codedaptive/mootx01-ce/mootx01
#
# Then wire into your AI clients (Claude, Cursor, Codex, etc.):
#   mootx01 install
#
# SHA256 values are updated automatically by scripts/update-formula.sh
# when a new release is tagged. Do not edit by hand.

class Mootx01 < Formula
  desc "On-device AI memory substrate: file, recall, and reason across sessions"
  homepage "https://github.com/codedaptive/mootx01-ce"
  license "FSL-1.1-ALv2"
  version "1.0.9-beta"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "e5cb95d5469fd1a498c98f40533a561cc4fd99e32858c4533bf4e3b3ad3b1115"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "b3ad1908584ae55a8b6890e6b4cb428cf7acbe3a3a13dc9e00717b4b568b71c0"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "f074f5ae952e66827b30c794490aceeab3f0028a6a0865e80556f0ddf05b021f"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "f9996403ec2a350674cf3f5cfb134cbb3834c3fedcdc0d57be99a6feef38fdb6"
    end
  end

  def install
    # Both binaries ship in every archive; moot-mgr is absent on Linux
    # (the Rust headless build ships it separately on some platforms).
    bin.install "mootx01"
    bin.install "moot-mgr" if File.exist?("moot-mgr")
  end

  def caveats
    <<~EOS
      Wire mootx01 into your AI clients (Claude, Cursor, Codex, and more):
        mootx01 install

      The installer detects which clients are present and wires each one
      automatically. Run with --yes to skip prompts:
        mootx01 install --yes

      Check your setup at any time:
        mootx01 status

      Upgrade to the latest release:
        brew upgrade mootx01
        mootx01 install   # rewires clients to the new binary path

      More at: https://github.com/codedaptive/mootx01-ce
    EOS
  end

  test do
    # Smoke-test: the binary must respond to --version without error.
    # Full MCP serve requires a running estate; skip in sandbox.
    # The binary reports the bare semantic version ("1.0.5") — the
    # pre-release qualifier ("-beta") lives only in the tag/formula, so
    # match the semver stem, not version.to_s.
    assert_match version.to_s.sub(/-.*$/, ""), shell_output("#{bin}/mootx01 --version")
  end
end
