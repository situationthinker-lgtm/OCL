import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // Native libSQL driver must stay unbundled.
  serverExternalPackages: ["@libsql/client", "@prisma/adapter-libsql"],
  // Server actions default to a 1 MB request body; image uploads go through them. Keep in step with MAX_IMAGE_BYTES.
  experimental: { serverActions: { bodySizeLimit: "26mb" } },
};

export default nextConfig;
