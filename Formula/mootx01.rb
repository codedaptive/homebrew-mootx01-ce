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
  version "1.0.28"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "18eaada84507496cce5cd3aca2f45eb5e5352b1b4596566e39d366de030a5920"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "3aa403e3dac7ca1e5b49652bf6ea25519ae8329b066b10fffcbefd345734a1b1"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "3ebb584dc356bc4280fba75d24f1f3120f9042c84d58a8305b50932b6515864e"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "314b615983bd6c073ff052e21d9644074449ed3658b18754d809c3d0f994a39f"
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

  # No post_install: Homebrew runs post_install inside a sandbox that only
  # permits writes under the Homebrew prefix/cache, so `mootx01 install` —
  # which writes user config (~/Library/Application Support/com.mootx01.ce,
  # ~/.claude.json MCP wiring, ~/Library/LaunchAgents) — fails there with
  # "Operation not permitted" (and, on machines with an existing estate,
  # used to block on the reuse/replace prompt). The wiring step therefore
  # runs in the user's terminal — see caveats.

  def caveats
    <<~EOS
      To finish setup, wire your AI clients and register the launchd services
      (this writes your user config, which Homebrew's sandbox cannot):

        #{opt_bin}/mootx01 install --yes --no-place --target claude-code

      The absolute path matters on machines that previously installed via
      install.sh or the .pkg: those place symlinks at ~/.local/bin/mootx01
      and ~/.local/bin/moot-mgr that shadow Homebrew's binaries on PATH and
      reject newer flags. Remove them (then `rehash` in zsh):

        rm -f ~/.local/bin/mootx01 ~/.local/bin/moot-mgr

      --no-place keeps the Homebrew-linked binary as the installed copy.
      With an existing MOOTx01 database, --yes reuses it; to start fresh
      instead, run: #{opt_bin}/mootx01 install --no-place --replace-db

      Afterwards the resident daemon (MCP server) and management console are
      registered as launchd services and start automatically at login.

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
