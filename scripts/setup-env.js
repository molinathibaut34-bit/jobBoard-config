/**
 * Cross-platform setup: copy .env.example -> .env and sync .NET User Secrets.
 * Invoked via: npm run setup:env
 */
const { execSync } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

const configDir = path.resolve(__dirname, "..");
const repoRoot = path.resolve(configDir, "..");
const envExample = path.join(configDir, ".env.example");
const envFile = path.join(configDir, ".env");
const apiProject = path.join(
  repoRoot,
  "back",
  "jobBoard-Api",
  "jobBoard-Api",
  "jobBoard-Api.csproj"
);

function getenv(filePath, key) {
  if (!fs.existsSync(filePath)) return null;
  const line = fs
    .readFileSync(filePath, "utf8")
    .split(/\r?\n/)
    .find((l) => new RegExp(`^\\s*${key}\\s*=`).test(l));
  if (!line) return null;
  return line
    .slice(line.indexOf("=") + 1)
    .trim()
    .replace(/^["']|["']$/g, "");
}

if (!fs.existsSync(envExample)) {
  console.error(`.env.example not found at ${envExample}`);
  process.exit(1);
}

if (!fs.existsSync(envFile)) {
  fs.copyFileSync(envExample, envFile);
  console.log(`Created ${envFile} from .env.example`);
} else {
  console.log(`Using existing ${envFile}`);
}

if (!fs.existsSync(apiProject)) {
  console.warn("API project not found; skipped User Secrets sync.");
  process.exit(0);
}

const jwtKey = getenv(envFile, "Jwt__Key");
const pgHost = getenv(envFile, "POSTGRES_HOST") || "localhost";
const pgPort = getenv(envFile, "POSTGRES_PORT") || "5434";
const pgDb = getenv(envFile, "POSTGRES_DB");
const pgUser = getenv(envFile, "POSTGRES_USER");
const pgPassword = getenv(envFile, "POSTGRES_PASSWORD");
const minioAccess =
  getenv(envFile, "Minio__AccessKey") || getenv(envFile, "MINIO_ROOT_USER");
const minioSecret =
  getenv(envFile, "Minio__SecretKey") || getenv(envFile, "MINIO_ROOT_PASSWORD");
const minioEndpoint =
  getenv(envFile, "Minio__Endpoint") || getenv(envFile, "MINIO_ENDPOINT");
const minioBucket =
  getenv(envFile, "Minio__BucketName") || getenv(envFile, "MINIO_BUCKET");
const minioPublic =
  getenv(envFile, "Minio__PublicBaseUrl") ||
  getenv(envFile, "MINIO_PUBLIC_BASE_URL");

let connection = getenv(envFile, "ConnectionStrings__DefaultConnection");
if (!connection) {
  connection = `Host=${pgHost};Port=${pgPort};Database=${pgDb};Username=${pgUser};Password=${pgPassword}`;
}

function setSecret(key, value) {
  if (!value) return;
  execSync(`dotnet user-secrets set "${key}" "${value}" --project "${apiProject}"`, {
    stdio: "ignore",
    shell: true,
  });
}

setSecret("Jwt:Key", jwtKey);
setSecret("ConnectionStrings:DefaultConnection", connection);
setSecret("Minio:AccessKey", minioAccess);
setSecret("Minio:SecretKey", minioSecret);
setSecret("Minio:Endpoint", minioEndpoint);
setSecret("Minio:BucketName", minioBucket);
setSecret("Minio:PublicBaseUrl", minioPublic);

console.log("User Secrets synchronized from .env");
console.log(
  `Done. Start infra with: npm run dev:docker  (from monorepo root or config/)`
);

// Keep platform scripts available for direct use
if (os.platform() === "win32") {
  // no-op; node path is the primary entry
}
