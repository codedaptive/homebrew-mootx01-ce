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
  version "1.1.2"

  # ── macOS arm64 (Apple Silicon) ──────────────────────────────────────────
  # Apple silicon only from 1.1.0 on: the release is built against macOS 27,
  # which Apple ships for arm64 alone, so there is no Intel asset to point at.
  on_macos do
    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-macos-arm64.tar.gz"
      # update-formula.sh writes the correct sha256 here after each release
      sha256 "cda3e6d223bd4baaab13385739ebf04eb9a24b96874f11d0b5006cb54973cf10"
    end

    on_intel do
      odie "mootx01 requires macOS 27 on Apple silicon; Intel Macs are not supported from 1.1.0 onward."
    end
  end

  # ── Linux x86_64 ─────────────────────────────────────────────────────────
  on_linux do
    on_intel do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-x86_64.tar.gz"
      sha256 "cd9775046af2012d584afbe8ee1bead8bb389e80145598b6f9fbaa0eac979dcf"
    end

    on_arm do
      url "https://github.com/codedaptive/mootx01-ce/releases/download/v#{version}/mootx01-v#{version}-linux-arm64.tar.gz"
      sha256 "ee8d852e4ce68d2a7bd06b9e4c037073f35f7ded08f5506a54091885d653084c"
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
