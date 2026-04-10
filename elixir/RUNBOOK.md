# Symphony Elixir Runbook

Operational reference for deploying and managing the Symphony Elixir orchestrator.

## Worker Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `LINEAR_API_KEY` | Yes | — | Linear API token for polling and updating issues. |
| `LINEAR_ASSIGNEE` | No | — | Linear user ID; when set, only issues assigned to this user are picked up. |
| `WORKER_MODE` | No | `live` | Set to `live` to run real Codex agents. Set to `simulate` to skip agent execution (CI/staging). |
| `SYMPHONY_SSH_CONFIG` | No | system default | Path to a custom SSH config file used when connecting to remote worker hosts. |

### WORKER_MODE

The worker mode controls whether the orchestrator dispatches real Codex agent runs.

- **`live`** (default): The orchestrator spawns Codex agent processes for each issue. Use in production.
- **`simulate`**: The orchestrator claims issues and runs through the polling loop, but skips Codex execution. Use in CI and staging to validate orchestration logic without incurring agent costs.

Set via `WORKER_MODE` environment variable or in `WORKFLOW.md` front matter:

```yaml
worker:
  mode: simulate
```

The startup log confirms the active mode:

```
Starting worker in live mode
```

or

```
Starting worker in simulate mode
```

### Production checklist

- [ ] `WORKER_MODE=live` set in production environment
- [ ] `LINEAR_API_KEY` set to a valid, non-expired token
- [ ] `WORKER_MODE=simulate` preserved in CI/staging environments
- [ ] SSH worker hosts configured in `WORKFLOW.md` under `worker.ssh_hosts` (if using remote workers)
- [ ] Verify startup log confirms `Starting worker in live mode` after deploy

## Secrets rotation

- **`LINEAR_API_KEY`**: Rotate in the Linear workspace settings. Update the production secret immediately — stale tokens cause the orchestrator to stop picking up issues.
