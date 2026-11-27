# Conditional Values

## Parameters

```yaml
inputs:
  condition:
    description: Conditional logic that evaluates to true or false
    required: true

  true:
    description: Output value if condition is true

  false:
    description: Output value if condition is false

outputs:
  value:
    description: Output value
```

## Usage

```yaml
steps:
- uses: SeligLabs/actionKit/condition@main
  id: condition
  with:
    condition: ${{ inputs.OVERRIDE == 'some value' }}
    true: Value to use for true
    false: Value to use for false

- name: Use Result
  run: echo "${{ steps.condition.outputs.value }}"
```
