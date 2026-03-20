# Global Claude Instructions

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

## Git and GitHub/GitLab
- Do not add `Co-Authored-By: Claude` or any AI attribution to commit messages, PR descriptions, issue bodies, or any other git or GitHub/GitLab content.
- Do not mention updates to Claude skills, CLAUDE.md files, hooks, or any AI tooling in commit messages, PR titles/descriptions, or issue comments — treat these as invisible infrastructure.
