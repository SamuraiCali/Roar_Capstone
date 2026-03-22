import { QueryResult } from "pg";
import { pool } from "../config/db";
import {
  DB_COMMENT,
  DB_COMMENT_WITH_REPLY_COUNT,
  DB_FOLLOW,
  DB_FOLLOWER,
  DB_USER,
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

export const dbGetFollowersFromUsername = async (username: string) => {
  const query = `
    SELECT u.id, u.username
    FROM users u
    JOIN followers f ON u.id = f.follower_id
    JOIN users target ON f.following_id = target.id
    WHERE target.username = $1;`;
  const result: QueryResult<DB_FOLLOWER> = await pool.query(query, [username]);
  return result.rows;
};

export const dbGetFollowersCountFromUsername = async (username: string) => {
  const result = await pool.query(
    "SELECT COUNT(*) FROM followers WHERE following_id = (SELECT id FROM users WHERE username = $1)",
    [username],
  );
  return Number(result.rows[0].count);
};

export const dbCreateFollow = async (followData: {
  follower_id: number;
  following_username: string;
}) => {
  const { follower_id, following_username } = followData;
  const result = await pool.query(
    `INSERT INTO followers (follower_id, following_id)
      SELECT $1, id
      FROM users
      WHERE username = $2
      ON CONFLICT DO NOTHING
      RETURNING *;`,
    [follower_id, following_username],
  );
  return result;
};

export const dbDeleteFollow = async (followData: {
  follower_id: number;
  following_username: string;
}) => {
  const { follower_id, following_username } = followData;
  const result = await pool.query(
    "DELETE FROM followers WHERE follower_id = $1 AND following_id = (SELECT id FROM users WHERE username = $2);",
    [follower_id, following_username],
  );
  return result.rowCount;
};

export const dbGetUserByUsername = async (username: string) => {
  const result: QueryResult<DB_USER> = await pool.query(
    "SELECT * FROM users WHERE username = $1",
    [username],
  );
  return result;
};
