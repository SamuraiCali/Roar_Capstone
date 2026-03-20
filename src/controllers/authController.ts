// src/controllers/authController.ts
import { Request, Response } from "express";
import { pool } from "../config/setupDB";
import { hashPassword, verifyPassword } from "../utils/passwordUtils";
import { DB_USER } from "../models/DatabaseTypes";

// const JWT_SECRET = process.env.JWT_SECRET || 'supersecretkey';

// Register a new user
export const register = async (req: Request, res: Response) => {
  const { username, email, password } = req.body;

  if (!username || !email || !password) {
    return res.status(400).json({ error: "All fields are required" });
  }

  try {
    const existingUser = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email],
    );
    if (existingUser.rows.length > 0) {
      return res.status(400).json({ error: "User already exists" });
    }

    const hashedPassword = await hashPassword(password);

    const result = await pool.query(
      "INSERT INTO users (username, email, password) VALUES ($1, $2, $3) RETURNING id, username, email",
      [username, email, hashedPassword],
    );

    const user = result.rows[0];
    res.status(201).json({ message: "User registered", user });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};

export const login = async (req: Request, res: Response) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: "Email and password are required" });
  }

  try {
    const userResult = await pool.query(
      "SELECT * FROM users WHERE email = $1",
      [email],
    );
    if (userResult.rows.length === 0) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const user: DB_USER = userResult.rows[0];

    const isMatch = await verifyPassword(password, user.password);
    if (!isMatch) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    // const token = jwt.sign({ id: user.id, email: user.email }, JWT_SECRET, {
    //   expiresIn: "1h",
    // });

    res.json({ message: "Login successful" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Server error" });
  }
};
