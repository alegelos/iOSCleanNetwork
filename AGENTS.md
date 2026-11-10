# Working in iOSCleanNetwork

This repository contains a Swift networking SDK and test utilities. Consumer
integration guidance lives in `skills/ioscleannetwork/references/integration.md`;
the complete fictional example is `skills/ioscleannetwork/assets/UserExample`.
Use `skills/ioscleannetwork/SKILL.md` when generating consumer integrations.

## Contracts

- Preserve public API compatibility unless the task explicitly changes it.
  Existing spellings such as `failingMethos` are public API, not invitations to
  silently rename them.
- Domain inputs and outputs stay independent of transport. New examples use
  `*Setup`, `*Provider`, request `*DTO`, response `*Response` and `.domain`.
- Keep examples fictional and small, with generic User/Item names and
  `example.com` URLs. Do not introduce customer, employer or reference-project
  names or credentials into documentation or examples.
- Maintain one technical guide inside the installable skill. Keep README.md
  and README_AI.md as introductions and routing, not competing specifications.
- Skill references and examples must survive installation outside this repo.
  Installing the Swift package does not install the skill into a consumer app.

## Verification

Use a Swift 6.2+ Apple toolchain on macOS 14+. From the repository root, the deterministic
consumer sample tests also compile both SDK products:

```sh
IOS_CLEAN_NETWORK_PATH="$PWD" swift test \
  --package-path skills/ioscleannetwork/assets/UserExample \
  --triple "$(uname -m)-apple-macosx14.0"
python3 -m unittest discover -s scripts/tests
```

Use Xcode and an available iOS simulator for iOS-specific changes. The sample's
default dependency is remote; set `IOS_CLEAN_NETWORK_PATH` to test this checkout.
If necessary, choose Xcode per command with `DEVELOPER_DIR` rather than changing
the user's global developer directory. These tests use fictional fixtures and
have no production access.

For guidance or example changes, also review API/version claims, Markdown links,
the skill description's scope and a standalone installation. For substantive
skill changes, exercise a realistic integration request in a temporary consumer
project. A schema validator alone does not prove useful agent behavior.
