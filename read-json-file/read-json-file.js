import fs from 'fs';
import * as core from '@actions/core';

/**
 * Read package.json file
 * @param {string} path
 * @returns {object}
 */
const readJson = function (path) {
    const jsonData = fs.readFileSync(path).toString();
    return JSON.parse(jsonData);
};

try {
    /**
     * Path to directory with package.json file
     * @type {string}
     */
    const path = core.getInput('path');
    /**
     * Build directory path
     * @type {string}
     */

    const buildDir = core.getInput('build_dir');

    const constructedPath = (buildDir ? `${ buildDir }/` : '') + path;

    /**
     * Get data from package.json file
     * @type {object}
     */
    const jsonData = readJson(constructedPath);

    core.setOutput('jsonData', jsonData);
} catch (error) {
    core.setFailed(error.message);
}
