import { QueryResult } from "pg";
import { pool } from "../config/setupDB";
import { DB_VIDEO } from "../models/DatabaseTypes";
export const dbLikeVideo = async (videoId: number, userId: number) => {
  const result = await pool.query(
    "INSERT INTO likes (user_id, video_id) VALUES $1, $2",
    [userId, videoId],
  );
  return result.rows[0];
};

export const dbUnlikeVideo = async (videoId: number, userId: number) => {
  const result = await pool.query(
    "DELETE FROM likes WHERE user_id = $1 AND video_id = $2",
    [userId, videoId],
  );
  return result.rowCount;
};

export const dbGetVideoKeys = async (
  limit: number = 5,
): Promise<DB_VIDEO[]> => {
  const result: QueryResult<DB_VIDEO> = await pool.query(
    "SELECT * FROM videos LIMIT $1",
    [limit],
  );
  return result.rows;
};
