// src/controllers/authController.ts
import { Request, Response } from "express";
import { pool } from "../config/db";
import { hashPassword, verifyPassword } from "../utils/passwordUtils";
import { DB_USER } from "../models/DatabaseTypes";
import { dbCreateUser, dbGetUserByEmail } from "../utils/dbUtils";
import jwt from "jsonwebtoken";

const JWT_SECRET = process.env.JWT_SECRET || "jwtsecret";

// Register a new user
export const register = async (req: Request, res: Response) => {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
        return res.status(400).json({ error: "All fields are required" });
    }

    try {
        const existingUser = await dbGetUserByEmail(email);
        if (existingUser) {
            return res.status(400).json({ error: "User already exists" });
        }

        const hashedPassword = await hashPassword(password);

        const user = await dbCreateUser({
            username: username,
            email: email,
            password: hashedPassword,
        });
        if (!user) {
            return res.status(500).json({
                error: "Internal Server Error: Failed to create user",
            });
        }

        const token = jwt.sign(
            { id: user.id, username: user.username },
            JWT_SECRET,
            {
                expiresIn: "7d",
            },
        );

        res.cookie("token", token, {
            httpOnly: true,
            secure: false,
            sameSite: "lax",
            maxAge: 1000 * 60 * 60 * 24 * 7,
        })
            .status(201)
            .json({ message: "User registered", user, token });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Server error" });
    }
};

export const login = async (req: Request, res: Response) => {
    const { email, password } = req.body;

    if (!email || !password) {
        return res
            .status(400)
            .json({ error: "Email and password are required" });
    }

    try {
        const user = await dbGetUserByEmail(email);
        if (!user) {
            return res.status(400).json({ error: "Invalid credentials" });
        }

        const isMatch = await verifyPassword(password, user.password);
        if (!isMatch) {
            return res.status(401).json({ error: "Invalid credentials" });
        }

        const token = jwt.sign(
            { id: user.id, username: user.username },
            JWT_SECRET,
            {
                expiresIn: "7d",
            },
        );

        res.cookie("token", token, {
            httpOnly: true,
            secure: false,
            sameSite: "lax",
            maxAge: 1000 * 60 * 60 * 24 * 7,
        }).json({ message: "Login successful", user, token });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Server error" });
    }
};
