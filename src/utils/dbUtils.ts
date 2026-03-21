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

export const dbGetFeedVideos = async (feedData: {
  user_id: number;
  limit: number;
}) => {
  const { user_id, limit } = feedData;
  const result = await pool.query(
    `
    SELECT 
      v.*,
      COUNT(DISTINCT l.user_id) AS like_count,
      COUNT(DISTINCT c.id) AS comment_count,
      EXISTS (
        SELECT 1
        FROM likes l2
        WHERE l2.video_id = v.id
          AND l2.user_id = $2
      ) AS is_liked
    FROM videos v
    LEFT JOIN likes l ON l.video_id = v.id
    LEFT JOIN comments c ON c.video_id = v.id
    GROUP BY v.id
    ORDER BY v.created_at DESC
    LIMIT $1
    `,
    [limit, user_id],
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

export const dbDeleteCommentById = async (commentData: {
  comment_id: number;
  user_id: number;
}) => {
  const { comment_id, user_id } = commentData;
  const result = await pool.query(
    "DELETE FROM comments WHERE id = $1 AND user_id = $2",
    [comment_id, user_id],
  );
  return result.rowCount;
};
