# homebrew-mootx01-ce

Homebrew tap for **MOOTx01 CE** — on-device AI memory substrate for Claude, Cursor, Codex, and other MCP clients.

MOOTx01 gives your AI coding tools persistent long-term memory: file decisions, recall prior context, and reason across sessions — all on-device, no cloud required.

## Install

```sh
brew install codedaptive/mootx01-ce/mootx01
```

Then wire it into your AI clients:

```sh
mootx01 install
```

The installer auto-detects Claude, Cursor, Codex, Gemini CLI, and a dozen other clients and wires each one in a single pass.

## Or use the curl installer

If you prefer not to use Homebrew:

```sh
curl -fsSL https://raw.githubusercontent.com/codedaptive/mootx01-ce/stable/1.0.x/install.sh | sh
```

## What gets installed

| Binary | Role |
|---|---|
| `mootx01` | MCP server + CLI (install, serve, query, db, status, upgrade) |
| `moot-mgr` | Management console + loopback dashboard (macOS) |

## After install

```sh
mootx01 status        # verify your setup
mootx01 install       # wire into AI clients (interactive)
mootx01 install --yes # wire all detected clients silently
```

## Upgrade

```sh
brew upgrade mootx01
mootx01 install       # rewires clients to the new binary path
```

## Uninstall

```sh
mootx01 uninstall     # remove from all wired clients
brew uninstall mootx01
```

## Source

- CE source: [codedaptive/mootx01-ce](https://github.com/codedaptive/mootx01-ce)
- License: [FSL-1.1-ALv2](https://github.com/codedaptive/mootx01-ce/blob/stable/1.0.x/LICENSE) (source-available; converts to Apache 2.0 after two years)

## Maintainers

This tap is maintained by [Codedaptive LLC](https://codedaptive.com).
