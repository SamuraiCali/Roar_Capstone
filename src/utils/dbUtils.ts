import { QueryResult } from "pg";
import { pool } from "../config/setupDB";
import {
  DB_COMMENT,
  DB_COMMENT_WITH_REPLY_COUNT,
  DB_VIDEO,
} from "../models/DatabaseTypes";

export const dbCreateLike = async (likeData: {
  userId: number;
  videoId: number;
}) => {
  const { userId, videoId } = likeData;
  const result = await pool.query(
    "INSERT INTO likes (user_id, video_id) VALUES ($1, $2) RETURNING *;",
    [userId, videoId],
  );
  return result.rows[0];
};

export const dbDeleteLike = async (likeData: {
  userId: number;
  videoId: number;
}) => {
  const { userId, videoId } = likeData;
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

export const dbGetCommentsWithReplyCount = async (videoId: number) => {
  const query = `SELECT c.*,
  COUNT(r.id) AS reply_count
  FROM comments c
  LEFT JOIN comments r 
    ON r.parent_comment_id = c.id
  WHERE c.video_id = $1
    AND c.parent_comment_id IS NULL
  GROUP BY c.id
  ORDER BY c.created_at DESC;`;

  const result: QueryResult<DB_COMMENT_WITH_REPLY_COUNT> = await pool.query(
    query,
    [videoId],
  );
  return result.rows;
};

export const dbCreateComment = async (commentData: {
  user_id: number;
  video_id: number;
  content: string;
  parent_comment_id: number | undefined;
}) => {
  const { user_id, video_id, content, parent_comment_id } = commentData;
  const result: QueryResult<DB_COMMENT> = await pool.query(
    "INSERT INTO comments (user_id, video_id, content, parent_comment_id) VALUES ($1, $2, $3, $4) RETURNING *;",
    [user_id, video_id, content, parent_comment_id],
  );
  return result.rows[0];
};

export const dbGetCommentById = async (id: number) => {
  const result: QueryResult<DB_COMMENT> = await pool.query(
    "SELECT * FROM comments WHERE id = $1",
    [id],
  );
  return result.rows.length > 0 ? result.rows[0] : null;
};

export const dbDeleteCommentById = async (id: number) => {
  const result = await pool.query("DELETE FROM comments WHERE id = $1", [id]);
  return result.rowCount;
};
