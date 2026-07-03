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
  version "1.0.11"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "2451ffefc3c87b0165a4d98c70f7b8c5d185849bd7855dcc9f9334ca64a7339e"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "9deb8d0c74a59e4ad9f9c31be6c9c9d9908581429d90415b57ea2e4dc35a49a0"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "8c85456d49e6f58cffe20c0dd093282fb59b90fd37416f7bd7f42be632104ccc"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "bd3d15b70baaff06d3f5bd2079e2bc77a4c6e1acf916a7627611f36191f8d28e"
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
