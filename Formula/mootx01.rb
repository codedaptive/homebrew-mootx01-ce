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
  version "1.0.24"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "e598b931a58f0e34764d20c4224c514c19c187c60ad910e641278415aa708eef"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "bd95f2d23cead0a5d62dbf3dc0b827612af122edd5f2a2a232edb03759304e93"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "aac4a0af1717b1bf561a495f226e192ba13784fef89ca4bff8805af2ffcb6d23"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "13d84927f91db4b6cb28f65e7f20fa1bdb7f59ccdf5c3d27f7a7caa74fb81aa1"
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
