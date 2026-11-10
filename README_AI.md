# Using iOSCleanNetwork with a coding agent

The reusable integration workflow is the
[`ioscleannetwork` skill](skills/ioscleannetwork/SKILL.md). Its
[integration guide](skills/ioscleannetwork/references/integration.md) and
[executable User example](skills/ioscleannetwork/assets/UserExample/) are the
canonical instructions and reference code. This file explains how to make
them available in the **application that consumes the SDK**.

## Install the plugin (recommended)

For Codex and Claude Code, install the public
[CleanNetwork plugin](https://github.com/alegelos/CleanNetworkPlugin). It bundles
the iOS and Android skills, guides and runnable examples, so you do not need to
copy skill folders into each consumer project. Install it once per agent
environment, even if you use both SDKs. Install the SDK dependency separately
using [the Swift package instructions](README.md#installation).

Run the commands for your client in a terminal with its CLI installed.
Codex needs a version that supports `codex plugin`.

### Codex

```sh
codex plugin marketplace add alegelos/CleanNetworkPlugin
codex plugin add cleannetwork@cleannetwork-tools
```

Start a new Codex session in your **consumer app or SDK**, then send:

```text
$cleannetwork:ioscleannetwork Implement GET /users/{id} using the API contract
and JSON below. Check the resolved SDK version, follow this project's existing
structure, map the response to Domain and add relevant tests.
```

Append your endpoint contract and representative JSON to that request. You can
also select the plugin's iOSCleanNetwork skill from the skill picker.

### Claude Code

```sh
claude plugin marketplace add alegelos/CleanNetworkPlugin
claude plugin install cleannetwork@cleannetwork-tools --scope user
```

Start a new Claude Code session in the **consumer app or SDK**, then send the
same request with `/cleannetwork:ioscleannetwork` instead of
`$cleannetwork:ioscleannetwork`.

### Check the installation

Run `codex plugin list` or `claude plugin list` and look for
`cleannetwork@cleannetwork-tools`. In the new session, ask the agent to identify
the loaded skill and the SDK version resolved by your project before integrating
an endpoint. If you already installed the standalone skill, select the plugin's
namespaced skill explicitly; review any local customizations before removing a
duplicate.

The public GitHub marketplace is available now. An official directory listing
requires a separate approval and publication; adding this marketplace is how to
find the plugin without relying on public directory search. See the
[plugin README](https://github.com/alegelos/CleanNetworkPlugin#readme) for desktop
installation, release ZIPs, updates and removal. Official CLI references:
[Codex](https://learn.chatgpt.com/docs/developer-commands) and
[Claude Code](https://code.claude.com/docs/en/discover-plugins).

## Install the standalone skill (alternative)

Use this option for GitHub Copilot, clients without plugin support, or a skill
copy committed to the consumer project for your team. If you installed the
plugin above, skip this section: it already contains the skill.

From a checkout of this repository:

```sh
python3 scripts/install_skill.py \
  /path/to/YourApp/.agents/skills/ioscleannetwork
```

Replace `/path/to/YourApp` with the consuming repository. The installer copies
the skill, guide and example, excludes build artifacts and refuses to overwrite
an existing destination. Review an existing installation before replacing it
with a newer version. Commit the installed folder if the team should share it.

### Choose the agent's installation folder

The same complete `ioscleannetwork` folder works with these clients. Paths below
are relative to the **consumer app**, not to the SDK checkout.

| Client | Project destination | Personal destination | Explicit activation |
| --- | --- | --- | --- |
| Codex | `.agents/skills/ioscleannetwork` | `~/.agents/skills/ioscleannetwork` | `$ioscleannetwork` or the skill selector |
| Claude Code | `.claude/skills/ioscleannetwork` | `~/.claude/skills/ioscleannetwork` | `/ioscleannetwork` |
| GitHub Copilot | `.github/skills/ioscleannetwork` | `~/.copilot/skills/ioscleannetwork` | In VS Code agent chat, select `/ioscleannetwork` from the `/` menu |

Pass the chosen destination to `scripts/install_skill.py`. For example, for
Claude Code:

```sh
python3 scripts/install_skill.py \
  /path/to/YourApp/.claude/skills/ioscleannetwork
```

Copilot also supports `.agents/skills` and `~/.agents/skills`, so a consumer
project can share one installed copy with Codex. Avoid duplicate copies with the
same name in locations scanned by the same client. Personal paths refer to the
machine running the agent; remote sessions need the skill in their own supported
location. Commit a project installation when the team should share it. Claude
cloud project threads use account-enabled skills instead of repository skills;
see its documentation for that distinct workflow.

You can also download `ioscleannetwork-skill-1.0.4.zip` from this SDK's
[release](https://github.com/alegelos/iOSCleanNetwork/releases/tag/1.0.4). Extract
it to a temporary directory and move the complete `ioscleannetwork` folder into
one of the locations above, without merging it into an older installation. Keep
`SKILL.md`, `references/`, `assets/` and `agents/` together. The SDK dependency is
installed separately; SwiftPM/Gradle does not install the skill for you.

Official setup references: [Codex](https://learn.chatgpt.com/docs/build-skills),
[Claude Code](https://code.claude.com/docs/en/skills),
[GitHub Copilot](https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills)
and [VS Code skill invocation](https://code.visualstudio.com/docs/agent-customization/agent-skills).

### Activate the standalone skill

In a Codex client that supports `$` skill mentions, start with:

```text
Use $ioscleannetwork to implement this endpoint in the current app.
Follow the app's existing structure. Here are the HTTP method, path,
request/response examples and authentication requirements: ...
```

Use the skill selector in clients with a different invocation UI. Automatic
selection is also allowed when the request matches the skill's description,
but explicit invocation is useful when verifying installation.

For persistent guidance, merge this small section into the consumer app's
existing `AGENTS.md` (adjust the path if you chose another location):

```markdown
## Networking

For endpoint integrations using iOSCleanNetwork, use the ioscleannetwork skill.
Read `.agents/skills/ioscleannetwork/SKILL.md` and its relevant references before
implementing the integration. Check the SDK version resolved by this project.
Keep domain inputs and outputs separate from transport DTOs and responses.
```

The `AGENTS.md` in the SDK repository guides work **in this repository**; it
does not automatically provide instructions to every consuming app. Codex's
[instruction discovery rules](https://learn.chatgpt.com/docs/agent-configuration/agents-md)
describe that scope. For other clients, put equivalent guidance in their
recognized project instruction file.

## How the skill works

`SKILL.md` supplies a name, a description of when to use the workflow, and the
integration steps. The agent can discover that description, then read the full
instructions and the linked guide/example when relevant. Explicit activation
helps ensure that this SDK's workflow is selected. It is reusable context for the
coding agent, not a runtime SDK plugin or an automatic code generator.

After installation, start a new session if the skill is absent from the selector.
Ask the agent to identify the loaded skill and SDK version, then give it a small
endpoint contract with request/response JSON. Check that it follows the app's
structure, maps transport types to Domain and runs appropriate tests. Successful
skill discovery alone does not prove that the generated integration is correct.

## Without installing a skill

Give the agent the SDK repository and explicitly ask it to read
`skills/ioscleannetwork/SKILL.md`, then the linked integration guide and relevant
example files. Ensure it can access those files. For a versioned SDK dependency,
use guidance compatible with the version you resolved, rather than assuming a
moving default branch describes every release.

## Inputs and expected result

Provide endpoint documentation or representative request/response JSON, the
base URL and authentication requirements, plus access to the consumer project
when you want an in-place integration. Examples alone do not prove that a field
is always present; use the API contract for required/optional fields.

The agent should adapt the existing app and generate the necessary domain
contract/models, Setup, Provider, transport types, mappings and relevant tests.
It should ask only for information that materially blocks correct behavior,
and report what it actually compiled or tested.

Use a ZIP when you request a standalone file deliverable. When working in a
checkout, the deliverable is the implemented and validated change in that
checkout. Explanation-only requests remain explanations.

## Maintain the integration material

Keep detailed SDK instructions in the skill's integration guide, and full Swift
examples in its executable sample. Update them together when a contract changes.
The skill metadata and validation commands are covered by [AGENTS.md](AGENTS.md).
