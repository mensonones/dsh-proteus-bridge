# dsh-command-proteus

A `/proteus <target>` slash command for the [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)
(`dsh`). It turns the single agent into the [Proteus](https://github.com/mensonones/Proteus)
coordinator and starts an autonomous continuous-vulnerability-research run — mirroring Claude
Code's `/proteus`.

The handler steers a coordinator kickoff prompt into the session (via `agent.steer`), so the
model drives the loop (Observe → Map → Hypothesize → Prioritize → Delegate → Validate →
Kill/Promote → Checkpoint → Replan) using the Proteus skills and `mcp__proteus__*` memory tools.

## Requires

The Proteus skills and MCP engine wired into the same profile (see the harness's Proteus
integration). Without them the command still fires, but the model has nothing to coordinate.

## Install

```bash
dsh plugin --profile web add dsh-command-proteus
```

Then insert it into that profile's `cordis.patch.yml`:

```yaml
- insert:
    - id: command-proteus
      name: dsh-command-proteus
```

## Use

```
/proteus localhost:8096
```

Calling a raw tool like `proteus_init` does one step; `/proteus` starts the whole campaign.
Only run it against authorized, in-scope targets.

## License

MIT.
