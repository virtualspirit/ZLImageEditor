# Deployment & Release Guide — ZLImageEditor

## Overview

ZLImageEditor is an iOS Swift library distributed via a **private CocoaPods podspec repo** hosted inside this repository. Consumers resolve it by pointing CocoaPods at this repo as a source — no CocoaPods trunk registration required.

```
developer pushes tag → CocoaPods resolves via Specs/ folder in this repo → consumers get the new version
```

---

## Branching

| Branch | Purpose |
|---|---|
| `default-config` | Main development branch — PRs merge here |
| `master` | Legacy / stable |

All version tags should point to commits on `default-config`.

---

## Versioning

This project uses **Semantic Versioning** (`MAJOR.MINOR.PATCH`).

| Change type | Version bump | Example |
|---|---|---|
| Bug fix | PATCH | `3.0.6` → `3.0.7` |
| New feature, backward-compatible | MINOR | `3.0.7` → `3.1.0` |
| Breaking change | MAJOR | `3.x.x` → `4.0.0` |

---

## Release Steps

### 1. Update the podspec version

Edit `ZLImageEditor.podspec`:

```ruby
s.version = 'X.Y.Z'
```

### 2. Add a new podspec to the Specs folder

Copy the updated podspec into the versioned Specs directory:

```bash
mkdir -p Specs/ZLImageEditor/X.Y.Z
cp ZLImageEditor.podspec Specs/ZLImageEditor/X.Y.Z/ZLImageEditor.podspec
```

### 3. Commit and push

```bash
git add ZLImageEditor.podspec Specs/
git commit -m "chore: bump version to X.Y.Z"
git push origin default-config
```

### 4. Create and push the tag

The tag name must match `s.version` in the podspec exactly:

```bash
git tag X.Y.Z
git push origin X.Y.Z
```

CocoaPods resolves the source by matching `s.version` (e.g. `3.0.6`) to the Git tag, **not** a `v` prefix.

---

## How the Private Podspec Repo Works

The `Specs/` folder in this repository acts as a CocoaPods source index:

```
ZLImageEditor/
└── Specs/
    └── ZLImageEditor/
        └── 3.0.6/
            └── ZLImageEditor.podspec   ← podspec for each released version
```

Consumers declare this repo as a source in their `Podfile`:

```ruby
source 'https://github.com/virtualspirit/ZLImageEditor.git'
source 'https://cdn.cocoapods.org/'
```

CocoaPods reads the `Specs/` index from this repo to resolve `ZLImageEditor` and its version, then fetches the actual source code using `:git` + `:tag` defined inside the podspec.

---

## GitHub Actions

There is currently **no CI workflow** for ZLImageEditor. Releases are done manually via tag push.

If a workflow is added in the future, it would trigger on tag push and run `xcodebuild` or `pod lib lint` to validate the podspec.

---

## Validating the Podspec Locally

Before tagging, validate the podspec:

```bash
pod lib lint ZLImageEditor.podspec --allow-warnings
```

Or against the private source:

```bash
pod spec lint ZLImageEditor.podspec --sources='https://github.com/virtualspirit/ZLImageEditor.git,https://cdn.cocoapods.org/' --allow-warnings
```

---

## Requirements

- **Xcode** with the target iOS SDK
- **CocoaPods** — install with `gem install cocoapods`
- **Ruby** — bundled with macOS or via `rbenv`

---

## Troubleshooting

**CocoaPods cannot find `ZLImageEditor`**
Ensure the consumer's `Podfile` has both `source` lines before any `target` block.
Run `pod repo update` to refresh the local source cache.

**Version not found after tagging**
Confirm the tag name matches `s.version` exactly (no `v` prefix).
Confirm the `Specs/ZLImageEditor/X.Y.Z/ZLImageEditor.podspec` file exists and is pushed.

**`pod lib lint` fails**
Check for missing files referenced in `s.source_files` or `s.resources`.
