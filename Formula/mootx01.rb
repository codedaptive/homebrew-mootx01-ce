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
  version "1.0.20"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "baa62822128ce96b831a59eb0564895a4e41a9d838af907b8bb59b0719049a39"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "e2ecb2210d16de06844f17f209d86d6ecb6907196177bd05bf4848417b1a8283"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "7155a39707a6432a0b8bd161863b89c180e7bcc1d08407611ab4b4558bfe37a1"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "5c67c50b96eba932ed42aac7c42611b0b931e78ee06eeec31210f00a23a430a1"
    end
  end

  def install
    bin.install "mootx01"
    bin.install "moot-mgr" if File.exist?("moot-mgr")

    # SPM resource bundles must be co-located with the binaries — each
    # Bundle.module target fatalErrors on first resource touch without its
    # <Target>_<Target>.bundle sibling. The macOS archives carry three:
    # LatticeLib (FDC data, lexicon, HMM model), EideticLib, and
    # swift-crypto. Linux archives carry none (Rust port, no SPM bundles).
    Dir.glob("*.bundle").each do |bundle|
      (bin/bundle).mkpath
      cp_r Dir["#{bundle}/*"], bin/bundle
    end
  end

  def post_install
    # Wire MCP clients and register launchd services. --no-place skips the
    # binary copy to ~/.mootx01/bin (Homebrew already placed it in its prefix
    # and linked it to PATH). --yes skips interactive prompts. --target
    # claude-code ensures the flow reaches launchd registration even if no
    # clients are auto-detected.
    system bin/"mootx01", "install", "--yes", "--no-place", "--target", "claude-code"
  end

  def caveats
    <<~EOS
      mootx01 has been installed and wired into detected AI clients.

      The resident daemon (MCP server) and management console are registered
      as launchd services and start automatically at login.

      Check your setup:
        mootx01 status

      Dashboard (when running):
        http://127.0.0.1:4200

      To re-wire after adding a new AI client:
        mootx01 install

      Upgrade to the latest release:
        brew upgrade mootx01

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
