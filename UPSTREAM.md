# Upstream

RegardingWork Dictate derives from the MIT-licensed Parrot project by Andrew
Jones / Digimata:

- Upstream: <https://github.com/digimata/parrot.git>
- Product repository:
  <https://github.com/shadstoneofficial/regardingwork-dictate.git>
- Preserved upstream tip at rebrand: `62f8d98a41422d55af21bfe337ec588dd7d2da46`

The original [LICENSE](LICENSE), copyright, commit graph, tags, and upstream
remote must remain intact. Product branding changes do not erase authorship.

## Sync procedure

```sh
git status --short
git fetch --prune upstream
git log --oneline --left-right --cherry-pick master...upstream/master
git switch -c agent/upstream-sync-YYYYMMDD master
git merge --no-ff upstream/master
```

Resolve conflicts by keeping RegardingWork runtime identifiers, privacy
defaults, signed-app packaging, and documentation while preserving upstream
functional improvements. Pay special attention to CLI names, LaunchAgent
labels, paths, transcript logging, debug recordings, installer behavior, and
release workflows.

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
