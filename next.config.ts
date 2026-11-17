import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Native SQLite driver must stay unbundled.
  serverExternalPackages: ["better-sqlite3", "@prisma/adapter-better-sqlite3"],
  // Server actions default to a 1 MB request body; image uploads go through them. Keep in step with MAX_IMAGE_BYTES.
  experimental: { serverActions: { bodySizeLimit: "26mb" } },
};

export default nextConfig;
