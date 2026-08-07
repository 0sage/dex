/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

import path from 'path';
import fs from 'fs';

const root = path.dirname(path.dirname(import.meta.dirname));
const nvmrcPath = path.join(root, '.nvmrc');
const version = fs.readFileSync(nvmrcPath, 'utf8').trim();

if (!version) {
	throw new Error('Failed to extract Node version from .nvmrc');
}

const platform = process.platform;
const arch = process.arch;

const node = platform === 'win32' ? 'node.exe' : 'node';
const nodePath = path.join(root, '.build', 'node', `v${version}`, `${platform}-${arch}`, node);

console.log(nodePath);
