# Global Claude Instructions

## Talk like a normal person

Be matter of fact without being bombastic. Write plainly, like a person would in normal work chat. No em-dashes. No emphatic validation words like "exactly", "precisely", "absolutely", "perfect". No hype or flattery. Just say the thing.

## Always validate, don't guess

Before acting on or asserting a fact (a channel name, an ID, a config value, a person, a file path, a command's behavior), validate it against the authoritative source: look it up, query it, or check the live system. If something was taken verbatim from a conversation or doc without independent verification, either verify it or explicitly flag it as unverified. Guessing produces mistakes that cost more time than validating up front.

## Clipboard — rich text with clickable links (macOS)

To copy text with clickable hyperlinks that paste correctly into apps like Slack,
use Swift to set both `.html` and `.string` types on the clipboard:

```swift
swift -e '
import AppKit
let html = "<html><body><a href=\"https://example.com\">link text</a></body></html>"
let plain = "link text (https://example.com)"
let pb = NSPasteboard.general
pb.clearContents()
pb.declareTypes([.html, .string], owner: nil)
pb.setString(html, forType: .html)
pb.setString(plain, forType: .string)
print("Copied!")
'
```

- `declareTypes` before setting values is required — setting without declaring causes paste to fail
- Always include `.string` as a fallback for apps that don't read HTML

## Reference Docs

When working with **Mermaid diagrams**, read `~/.claude/docs/unicode-symbols-mermaid.md` for the unicode symbol conventions to use in diagram nodes.

## GitLab CLI (glab) — always use numeric project IDs

On Omnistation, `gitlab-master.nvidia.com` routes through a local proxy that mishandles URL-encoded slashes, so `glab api projects/namespace%2Fproject/...` returns 404. **Always use numeric project IDs**: `glab api projects/<id>/...`.

Known project IDs:

| Project path | ID |
|---|---|
| `dgxc-lepton/lepton` | `186903` |
| `cgruenwald/lepton-dev-tools` (lepton-dev) | `275279` |
| `dgxc-lepton/ai-coding` | `229203` |
| `hwinf-cs/scheduling/slurm` | `213192` |
| `hwinf-cs/scheduling/tempus` | `168241` |
| `cgruenwald/scheduling-dev` | `317906` |

High-level glab commands (`glab mr view`, `glab ci status`) reject numeric IDs — route those through envy: `ssh envy 'zsh -lc "glab mr view 5801 -R dgxc-lepton/lepton"'`. To look up a new ID: `ssh envy 'zsh -lc "glab api projects/namespace%2Fproject"' | jq .id`.

## Git and GitHub/GitLab
- Do not add `Co-Authored-By: Claude` or any AI attribution to commit messages, PR descriptions, issue bodies, or any other git or GitHub/GitLab content.
- Do not mention updates to Claude skills, CLAUDE.md files, hooks, or any AI tooling in commit messages, PR titles/descriptions, or issue comments — treat these as invisible infrastructure.
