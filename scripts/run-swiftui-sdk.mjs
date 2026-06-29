#!/usr/bin/env node
/**
 * Build or test RheoSwiftUI against the iOS Simulator SDK.
 * Plain `swift test` on macOS targets the host and fails (no UIKit).
 */
import { execFileSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { resolveIosSimulatorDestination } from './swiftui-simulator.mjs';

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const swiftuiDir = path.join(repoRoot, 'packages/sdks/swiftui');

const mode = process.argv[2];
if (mode !== 'build' && mode !== 'test') {
  console.error('Usage: node scripts/run-swiftui-sdk.mjs <build|test>');
  process.exit(1);
}

const xcodeDestination = mode === 'test' ? resolveIosSimulatorDestination() : null;

const requireCommand = (command, args, hint) => {
  try {
    execFileSync(command, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
  } catch {
    console.error(hint);
    process.exit(1);
  }
};

requireCommand(
  'swift',
  ['--version'],
  'Swift toolchain not found. Install Xcode, then run:\n  xcode-select -s /Applications/Xcode.app/Contents/Developer',
);
requireCommand(
  'xcrun',
  ['--sdk', 'iphonesimulator', '--show-sdk-path'],
  'iOS Simulator SDK not found. Install Xcode with iOS platform support.',
);

const sdkPath = execFileSync('xcrun', ['--sdk', 'iphonesimulator', '--show-sdk-path'], {
  encoding: 'utf8',
}).trim();

const deploymentTarget = process.env.SWIFTUI_IOS_DEPLOYMENT_TARGET ?? '16.0';
const arch = process.arch === 'arm64' ? 'arm64' : 'x86_64';
const triple = `${arch}-apple-ios${deploymentTarget}-simulator`;

if (xcodeDestination) {
  console.log(`[swiftui-sdk] ${mode} (destination=${xcodeDestination})`);
} else {
  console.log(`[swiftui-sdk] ${mode}`);
}

const swiftPlatformArgs = [
  '--sdk',
  sdkPath,
  '-Xswiftc',
  '-target',
  '-Xswiftc',
  triple,
];

if (mode === 'test') {
  execFileSync(
    'xcodebuild',
    [
      'test',
      '-scheme',
      'RheoSwiftUI-Package',
      '-destination',
      xcodeDestination,
      '-skipPackagePluginValidation',
    ],
    { cwd: swiftuiDir, stdio: 'inherit' },
  );
} else {
  console.log(`[swiftui-sdk] build (sdk=iphonesimulator, target=${triple})`);
  execFileSync('swift', ['build', ...swiftPlatformArgs], { cwd: swiftuiDir, stdio: 'inherit' });
}
