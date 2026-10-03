/**
 * Ensure Docker engine is running, then start JobBoard compose stack.
 * Invoked via: npm run dev:docker
 */
const { execFileSync, execSync, spawn } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

const configDir = path.resolve(__dirname, "..");
const envFile = path.join(configDir, ".env");
const maxWaitMs = 120_000;
const pollMs = 2_000;

function log(message) {
  console.log(message);
}

function dockerInfoOk() {
  try {
    execFileSync("docker", ["info"], {
      stdio: "ignore",
      shell: false,
      windowsHide: true,
    });
    return true;
  } catch {
    return false;
  }
}

function dockerAvailable() {
  try {
    execFileSync("docker", ["version", "--format", "{{.Client.Version}}"], {
      stdio: "ignore",
      shell: false,
      windowsHide: true,
    });
    return true;
  } catch {
    return false;
  }
}

function startDockerDesktopWindows() {
  const candidates = [
    path.join(
      process.env["ProgramFiles"] || "C:\\Program Files",
      "Docker",
      "Docker",
      "Docker Desktop.exe"
    ),
    path.join(
      process.env["ProgramFiles(x86)"] || "C:\\Program Files (x86)",
      "Docker",
      "Docker",
      "Docker Desktop.exe"
    ),
    path.join(
      process.env.LOCALAPPDATA || "",
      "Docker",
      "Docker Desktop.exe"
    ),
  ].filter(Boolean);

  const exe = candidates.find((p) => fs.existsSync(p));
  if (!exe) {
    throw new Error(
      "Docker Desktop introuvable. Installez Docker Desktop puis réessayez."
    );
  }

  log(`Démarrage de Docker Desktop… (${exe})`);
  spawn(exe, [], {
    detached: true,
    stdio: "ignore",
    windowsHide: true,
  }).unref();
}

function startDockerDesktopMac() {
  log("Démarrage de Docker Desktop…");
  execSync('open -a "Docker"', { stdio: "ignore" });
}

function startDockerEngine() {
  const platform = os.platform();
  if (platform === "win32") {
    startDockerDesktopWindows();
    return;
  }
  if (platform === "darwin") {
    startDockerDesktopMac();
    return;
  }
  throw new Error(
    "Le démon Docker n'est pas démarré. Lancez Docker (ou le service docker) puis réessayez."
  );
}

function sleep(ms) {
  try {
    Atomics.wait(new Int32Array(new SharedArrayBuffer(4)), 0, 0, ms);
  } catch {
    const end = Date.now() + ms;
    while (Date.now() < end) {
      // busy-wait fallback when SharedArrayBuffer / Atomics.wait is unavailable
    }
  }
}

function waitForDocker() {
  const started = Date.now();
  while (Date.now() - started < maxWaitMs) {
    if (dockerInfoOk()) {
      log("Docker est prêt.");
      return;
    }
    process.stdout.write(".");
    sleep(pollMs);
  }
  process.stdout.write("\n");
  throw new Error(
    `Docker n'est pas prêt après ${Math.round(maxWaitMs / 1000)}s.`
  );
}

function ensureEnvFile() {
  if (fs.existsSync(envFile)) {
    return;
  }
  const example = path.join(configDir, ".env.example");
  if (!fs.existsSync(example)) {
    throw new Error(`.env manquant et .env.example introuvable dans ${configDir}`);
  }
  fs.copyFileSync(example, envFile);
  log(`Créé ${envFile} depuis .env.example`);
}

function composeUp() {
  log("Lancement des conteneurs (docker compose up -d)…");
  execFileSync(
    "docker",
    [
      "compose",
      "-p",
      "jobboard",
      "--env-file",
      ".env",
      "up",
      "-d",
      "--remove-orphans",
    ],
    {
      cwd: configDir,
      stdio: "inherit",
      shell: false,
      windowsHide: true,
    }
  );
}

function main() {
  if (!dockerAvailable()) {
    throw new Error(
      "La commande `docker` est introuvable dans le PATH. Installez Docker Desktop."
    );
  }

  ensureEnvFile();

  if (dockerInfoOk()) {
    log("Docker est déjà démarré.");
  } else {
    startDockerEngine();
    process.stdout.write("Attente du démon Docker");
    waitForDocker();
  }

  composeUp();
  log("Infra JobBoard démarrée (Postgres + MinIO + Mailpit).");
}

try {
  main();
} catch (err) {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
}
