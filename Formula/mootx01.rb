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
  version "1.1.0"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "ff2ae1dd5410f856781a3b86bfea56c625e68b7f0f2a6240d311377744274705"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "ce9564c25736dbddef0d6d3b8a8f20523e01611ceb9d0edc858e970bac0591f1"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "63ce0860aae0194c556cb3eae39a80d62d8fb4d750c02901f7a412f1329cfe14"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "7566b2b0f70d06fd575f9acf798fd6c9fcf8c6aa8c2970ca0ce0d8cee6bc402b"
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

  # Caveat design: ONE command, one check, one line per edge case, no
  # rationale — the why (sandbox, shadowing, flag semantics) lives in code
  # comments and `mootx01 install --help`, not in front of the user.
  def caveats
    <<~EOS
      Finish setup (wires your AI clients and starts the background services):

        #{opt_bin}/mootx01 install --yes --no-place --target claude-code

      Verify:    mootx01 status
      Dashboard: http://127.0.0.1:4200

      If `mootx01 --version` shows an older version, an earlier non-Homebrew
      install is shadowing this one — fix:
        rm -f ~/.local/bin/mootx01 ~/.local/bin/moot-mgr

      More: https://github.com/codedaptive/mootx01-ce
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
