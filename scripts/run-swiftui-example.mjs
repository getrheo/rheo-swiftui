#!/usr/bin/env node
/**
 * Build or run the RheoSwiftUI example app on the iOS Simulator.
 */
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import readline from 'node:readline';
import { fileURLToPath } from 'node:url';
import {
  DEFAULT_SWIFTUI_SIMULATOR_NAME,
  findSimulator,
  listIosSimulators,
} from './swiftui-simulator.mjs';

const DEFAULT_SWIFTUI_SIMULATOR_OS = '26.5';
const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const exampleDir = path.join(repoRoot, 'apps/example-swiftui');
const scheme = 'RheoExampleSwiftUI';
const bundleId = 'app.rheo.example.swiftui';

const mode = process.argv[2];
if (mode !== 'build' && mode !== 'run') {
  console.error('Usage: node scripts/run-swiftui-example.mjs <build|run> [--device NAME] [--os VERSION] [--pick]');
  process.exit(1);
}

const parseFlags = (argv) => {
  let device = null;
  let os = null;
  let pick = false;
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--device' && argv[i + 1]) {
      device = argv[++i];
    } else if (arg === '--os' && argv[i + 1]) {
      os = argv[++i];
    } else if (arg === '--pick') {
      pick = true;
    }
  }
  return { device, os, pick };
};

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

const formatDestination = (sim) =>
  `platform=iOS Simulator,name=${sim.name},OS=${sim.osVersion}`;

const pickSimulatorInteractively = async (simulators) => {
  simulators.forEach((sim, index) => {
    const booted = sim.state === 'Booted' ? ' [Booted]' : '';
    console.log(`${index + 1}. ${sim.name} (iOS ${sim.osVersion})${booted}`);
  });

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const answer = await new Promise((resolve) => {
    rl.question('Pick a simulator (number): ', resolve);
  });
  rl.close();

  const index = Number.parseInt(answer, 10) - 1;
  if (!Number.isFinite(index) || index < 0 || index >= simulators.length) {
    console.error('Invalid selection.');
    process.exit(1);
  }
  return simulators[index];
};

const resolveExampleSimulator = async (flags) => {
  const override = process.env.SWIFTUI_SIMULATOR_DESTINATION?.trim();
  if (override && !flags.pick) {
    return { destination: override, udid: null };
  }

  const simulators = listIosSimulators();
  if (simulators.length === 0) {
    console.error('No available iOS simulators. Install an iOS runtime in Xcode (Settings → Platforms).');
    process.exit(1);
  }

  const envName = process.env.SWIFTUI_SIMULATOR_NAME?.trim();
  const envOs = process.env.SWIFTUI_SIMULATOR_OS?.trim();
  const pinnedName = flags.device ?? envName;
  const pinnedOs = flags.os ?? envOs;
  const hasPin = Boolean(pinnedName || pinnedOs);
  const useInteractive = flags.pick || (process.stdin.isTTY && !hasPin);

  let selected = null;
  if (useInteractive) {
    selected = await pickSimulatorInteractively(simulators);
  } else if (pinnedName && pinnedOs) {
    selected = findSimulator(simulators, pinnedName, pinnedOs);
    if (!selected) {
      console.warn(
        `[swiftui-example] Simulator ${pinnedName} (iOS ${pinnedOs}) not found; using defaults.`,
      );
    }
  } else if (pinnedName) {
    const matches = simulators.filter((sim) => sim.name === pinnedName);
    selected = matches[0] ?? null;
    if (!selected) {
      console.warn(`[swiftui-example] Simulator ${pinnedName} not found; using defaults.`);
    }
  }

  if (!selected) {
    selected =
      findSimulator(simulators, DEFAULT_SWIFTUI_SIMULATOR_NAME, DEFAULT_SWIFTUI_SIMULATOR_OS)
      ?? simulators.find((sim) => sim.name === DEFAULT_SWIFTUI_SIMULATOR_NAME)
      ?? simulators.find((sim) => sim.name.includes('iPhone'))
      ?? simulators[0];
  }

  return { destination: formatDestination(selected), udid: selected.udid };
};

const parseBuildSettings = (output) => {
  const settings = {};
  for (const line of output.split('\n')) {
    const match = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)$/);
    if (match) {
      settings[match[1]] = match[2].trim();
    }
  }
  return settings;
};

const xcodebuild = (destination, action, extraArgs = []) => {
  execFileSync(
    'xcodebuild',
    [
      action,
      '-scheme',
      scheme,
      '-destination',
      destination,
      '-skipPackagePluginValidation',
      ...extraArgs,
    ],
    { cwd: exampleDir, stdio: 'inherit' },
  );
};

const getBuiltAppPath = (destination) => {
  const output = execFileSync(
    'xcodebuild',
    [
      '-scheme',
      scheme,
      '-destination',
      destination,
      '-showBuildSettings',
      '-skipPackagePluginValidation',
    ],
    { cwd: exampleDir, encoding: 'utf8' },
  );
  const settings = parseBuildSettings(output);
  const productsDir = settings.BUILT_PRODUCTS_DIR;
  const productName = settings.FULL_PRODUCT_NAME;
  if (!productsDir || !productName) {
    throw new Error('Could not resolve built .app path from xcodebuild settings.');
  }
  return path.join(productsDir, productName);
};

const bootSimulator = (udid) => {
  try {
    execFileSync('xcrun', ['simctl', 'boot', udid], { stdio: 'ignore' });
  } catch {
    // Already booted or boot in progress.
  }
  execFileSync('open', ['-a', 'Simulator'], { stdio: 'ignore' });
};

const installAndLaunch = (udid, appPath) => {
  if (!fs.existsSync(appPath)) {
    throw new Error(`Built app not found at ${appPath}`);
  }
  bootSimulator(udid);
  execFileSync('xcrun', ['simctl', 'install', udid, appPath], { stdio: 'inherit' });
  execFileSync('xcrun', ['simctl', 'launch', udid, bundleId], { stdio: 'inherit' });
};

const main = async () => {
  const flags = parseFlags(process.argv.slice(3));
  const { destination, udid } = await resolveExampleSimulator(flags);

  console.log(`[swiftui-example] ${mode} (destination=${destination})`);
  xcodebuild(destination, 'build');

  if (mode === 'run') {
    if (!udid) {
      console.error('[swiftui-example] Run mode requires a simulator UDID (set device/os or use --pick).');
      process.exit(1);
    }
    const appPath = getBuiltAppPath(destination);
    installAndLaunch(udid, appPath);
  }
};

main().catch((error) => {
  console.error(error instanceof Error ? error.message : String(error));
  process.exit(1);
});
