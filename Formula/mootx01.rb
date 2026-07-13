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
  version "1.0.31"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "4dcdf9caab8f68528be630370282f04c2e76640dfa9d1f011d2fe2617d2a4955"
    end

    # ── macOS x86_64 (Intel) ─────────────────────────────────────────────
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-x86_64.tar.gz"
      sha256 "5c20bc694fe907c6c80c5bf57464681708d8b162400a0c5023ed878bfd9f1770"
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "f777b9c1a03c2e46d6f39aa89a5df2f1bf78e665d321f4db90779b16468a948b"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "bad2566c21a170f50d408f25d6203bfdf0d46b2b9d0849927d89d26e746ccc0b"
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
