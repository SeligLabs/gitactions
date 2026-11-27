# Next Version

Works out the next `vX.Y.Z` from the repository's newest tag of that shape. Moving major tags (`v1`) and build tags (`v1.2.3+4`) are passed over. Needs `fetch-depth: 0`.

```yaml
steps:
  - uses: actions/checkout@v7
    with:
      fetch-depth: 0
  - id: version
    uses: SeligLabs/actionKit/next-version@v1
    with:
      BUMP: ${{ inputs.bump || 'patch' }}
      INITIAL: v0.0.0
  - uses: SeligLabs/actionKit/tag-release@v1
    with:
      TAG: ${{ steps.version.outputs.TAG }}
```

| Input     | Value                                                                                  | Default |
| --------- | -------------------------------------------------------------------------------------- | ------- |
| `BUMP`    | `patch`, `minor` or `major`.                                                           | `patch` |
| `INITIAL` | Where to start when there is no `vX.Y.Z` tag yet, e.g. `v0.0.0`. Unset: fail instead. | none    |

| Output     | Value                                                |
| ---------- | ---------------------------------------------------- |
| `TAG`      | The next tag, e.g. `v1.4.0`.                         |
| `VERSION`  | The same without the `v`, e.g. `1.4.0`.              |
| `MAJOR`    | Its major tag, e.g. `v1`.                            |
| `PREVIOUS` | The tag it advanced from, empty when it used `INITIAL`. |
