import * as core from '@actions/core';

try {
    // Conditional logic and values
    const condition = core.getInput('condition', {required: true})
    const ifTrue = core.getInput('true')
    const ifFalse = core.getInput('false')

    // Evaluate logic and return correct value
    core.setOutput('value', condition === 'true' ? ifTrue : ifFalse)
} catch (error) {
    core.setFailed(error.message);
}
