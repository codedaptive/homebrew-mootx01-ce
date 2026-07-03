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
  version "1.0.12"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "5f6d8ee73692cf0ef8ad80e518df43bc8fe75de86f625c36b3920b838296784b"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "46ca58698e62931deb9592e369100679be4121fc0c49443aaf7928cd925e45fa"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "6fd855815f47fec2ca0f15d89f3c6157459002c20ca36f62318f5b683dde4329"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "32bb0491bf086fbb63175a0332ea77ff0e84bf4d2adc14581c2a25581e00ba70"
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
