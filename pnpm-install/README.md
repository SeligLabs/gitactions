# pnpm Install

Sets up Node (from `.nvmrc`) and pnpm (from `packageManager`), then restores the workspace's installed `node_modules` from the Actions cache. `pnpm install --frozen-lockfile` runs only on a miss, which happens when `pnpm-lock.yaml`, `pnpm-workspace.yaml` or the Node version changed.

On a miss the cache is saved straight after the install, so parallel jobs and later runs can use it even if the rest of the job fails.

It caches the installed tree rather than the pnpm store, so a hit skips the install step entirely.

```yaml
steps:
  - uses: actions/checkout@v7
  - uses: SeligLabs/gitactions/pnpm-install@v1
  - run: pnpm test
```

| Input               | Value                          | Default  |
| ------------------- | ------------------------------ | -------- |
| `NODE_VERSION_FILE` | File holding the Node version. | `.nvmrc` |

| Output      | Value                                                                     |
| ----------- | ------------------------------------------------------------------------- |
| `CACHE_HIT` | `"true"` when `node_modules` came from the cache and install was skipped. |

Covers `node_modules`, `apps/*/node_modules` and `packages/*/node_modules`, the layout of SeligLabs/template-website.
