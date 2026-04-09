import { randomBytes, scrypt as _scrypt } from "crypto";
import { promisify } from "util";

const scrypt = promisify(_scrypt);

export async function hashPassword(password: string) {
  const salt = randomBytes(16).toString("hex"); // unique salt per password
  const derivedKey = (await scrypt(password, salt, 64)) as Buffer;
  return `${salt}:${derivedKey.toString("hex")}`;
}

export async function verifyPassword(password: string, stored: string) {
  const parts = stored.split(":");
  if (parts.length !== 2) return false;
  const [salt, key] = parts;
  const derivedKey = (await scrypt(password, salt!, 64)) as Buffer;
  return key === derivedKey.toString("hex");
}
