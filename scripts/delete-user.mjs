#!/usr/bin/env node
/**
 * Deletes a user (and all owned records via cascade) by email — used to
 * clean up after scripts/smoke-api.mjs or manual testing.
 *
 * Requires DATABASE_URL in the environment.
 *
 * Usage:
 *   DATABASE_URL=postgresql://... node scripts/delete-user.mjs user@example.com
 */
import { createRequire } from 'node:module';

// Resolve the Prisma client from the API package regardless of cwd.
const require = createRequire(new URL('../apps/api/package.json', import.meta.url));
const { PrismaClient } = require('@prisma/client');

const email = process.argv[2];
if (!email) {
  console.error('Usage: node scripts/delete-user.mjs <email>');
  process.exit(1);
}
if (!process.env.DATABASE_URL) {
  console.error('DATABASE_URL is required');
  process.exit(1);
}

const prisma = new PrismaClient();
try {
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    console.log(`No user found for ${email}`);
    process.exit(0);
  }
  await prisma.user.delete({ where: { id: user.id } });
  console.log(`Deleted ${email} (id ${user.id}) and cascade-owned records`);
} finally {
  await prisma.$disconnect();
}