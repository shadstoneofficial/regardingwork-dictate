# Upstream

RegardingWork Dictate derives from the MIT-licensed Parrot project by Andrew
Jones / Digimata:

- Original upstream: <https://github.com/digimata/parrot.git>
- Current upstream (verified transfer, 2026-10-03):
  <https://github.com/humanitas-labs/parrot.git>
- Product repository:
  <https://github.com/shadstoneofficial/regardingwork-dictate.git>
- Preserved upstream tip at rebrand: `62f8d98a41422d55af21bfe337ec588dd7d2da46`

The original [LICENSE](LICENSE), copyright, commit graph, tags, and upstream
remote must remain intact. Product branding changes do not erase authorship.

## Selective sync procedure

Upstream has evolved substantially since the rebrand. Review changes before
porting them; do not merge its entire default branch into this product without
a separately reviewed integration plan. The original remote URL currently
redirects to the transferred repository; keeping it does not lose history.

```sh
git status --short
git fetch --prune upstream
git log --oneline --left-right --cherry-pick master...upstream/master
git switch -c agent/upstream-sync-YYYYMMDD origin/master
```

Choose one bounded feature or fix, record its upstream commit and adaptations
in the review notes, and port it with regression tests. Use a stacked branch
and name its prerequisite PR when it relies on unmerged product improvements.
Keep RegardingWork runtime identifiers, privacy defaults, signed-app identity,
and packaging. Do not import upstream's update feed, signing keys, analytics,
installer behavior, runtime paths, or release credentials.

Re-check licenses for newly imported code without replacing the original
`LICENSE`. The modifier-key/gesture implementation in this revision is adapted
from upstream commit `a67e7f3` (HotkeyKey, Gesture, and matching logic), reviewed
against `0eb4708`. Its additional Humanitas Labs MIT notice is preserved in
[docs/licenses/PARROT_UPSTREAM_MIT.txt](docs/licenses/PARROT_UPSTREAM_MIT.txt).
No dependency versions changed. See the
[2026-10-03 review](docs/UPSTREAM_REVIEW_2026-10-03.md) for adopted and deferred work.

Then run:

```sh
swift build -c release
swift test
.build/release/regardingwork-dictate --help
rg -n -i 'parrot|digimata|com\.digimata\.parrot' \
  Sources Tests Packaging scripts .github README.md docs AGENTS.md
```

Any remaining original names must be limited to licensing, copyright,
attribution, migration notes, or this upstream-sync guide. Push the sync branch
and open a draft pull request; never merge upstream directly into the default
branch.

## Contributing back

Prepare contributions on a branch based on the current upstream default
branch, not on the branded product branch. Use a dedicated GitHub fork for
upstream PRs: this product repository is intentionally independent of GitHub's
fork network. Keep the upstream's naming, architecture and existing UX policy.
Search issues/PRs before work; discuss larger UI or behavior changes first.
Submit one small change with tests and manual verification limitations, never
our branding, signing configuration, website, or a wholesale fork diff.
Use GitHub's noreply email for new commits. Do not rewrite upstream authorship.
