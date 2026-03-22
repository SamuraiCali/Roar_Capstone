import { Request, Response } from "express";
import { pool } from "../config/db";

const getTable = async (table: string) => {
  return await pool.query(`SELECT * FROM ${table}`);
};

export const getVideosAdmin = async (req: Request, res: Response) => {
  try {
    const result = await getTable("videos");
    res.status(200).json({ videos: result.rows });
  } catch (err) {
    console.log("Error while fetching videos table: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getUsersAdmin = async (req: Request, res: Response) => {
  try {
    const result = await getTable("users");
    res.status(200).json({ users: result.rows });
  } catch (err) {
    console.log("Error while fetching users table: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getLikesAdmin = async (req: Request, res: Response) => {
  try {
    const result = await getTable("likes");
    res.status(200).json({ likes: result.rows });
  } catch (err) {
    console.log("Error while fetching likes table: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getCommentsAdmin = async (req: Request, res: Response) => {
  try {
    const result = await getTable("comments");
    res.status(200).json({ comments: result.rows });
  } catch (err) {
    console.log("Error while fetching comments table: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getFollowersAdmin = async (req: Request, res: Response) => {
  try {
    console.log("Attempting to fetch followers");
    const result = await getTable("followers");
    res.status(200).json({ comments: result.rows });
  } catch (err) {
    console.log("Error while fetching followers table: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
