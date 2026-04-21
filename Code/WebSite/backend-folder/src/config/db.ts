import { Pool } from "pg";

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || "5432"),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
});

export const testDatabaseConnection = async () => {
  try {
    const client = await pool.connect();
    console.log("Connected to PostgreSQL successfully");
    client.release();
  } catch (err) {
    console.error("PostgreSQL connection error", err);
  }
};
