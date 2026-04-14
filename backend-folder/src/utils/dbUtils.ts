import { QueryResult } from "pg";
import { pool } from "../config/db";
import {
    DB_COMMENT,
    DB_COMMENT_WITH_REPLY_COUNT,
    DB_FOLLOW,
    DB_FOLLOWER,
    DB_USER,
    DB_VIDEO,
} from "../models/DatabaseTypes";

export const dbCreateUser = async (userData: {
    username: string;
    email: string;
    password: string;
}) => {
    const { username, email, password } = userData;
    const result: QueryResult<DB_USER> = await pool.query(
        "INSERT INTO users (username, email, password) VALUES ($1, $2, $3) RETURNING *",
        [username, email, password],
    );
    return result.rowCount ? result.rows[0] : null;
};

export const dbGetUserByEmail = async (email: string) => {
    const result: QueryResult<DB_USER> = await pool.query(
        "SELECT * FROM users WHERE email = $1",
        [email],
    );
    return result.rowCount ? result.rows[0] : null;
};

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

interface videoData {
    user_id: number;
    key: string;
    title: string | null;
    description: string | null;
    duration_seconds: number | null;
    width: number | null;
    height: number | null;
}
export const dbCreateVideo = async (videoData: videoData) => {
    const {
        user_id,
        key,
        title = null,
        description = null,
        duration_seconds = null,
        width = null,
        height = null,
    } = videoData;
    const query = `
      INSERT INTO videos (user_id, key, title, description, duration_seconds, width, height)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;
    const values = [
        user_id,
        key,
        title,
        description,
        duration_seconds,
        width,
        height,
    ];
    const result = await pool.query(query, values);
    return result.rowCount ? result.rows[0] : null;
};

export const dbGetFeedVideos = async (feedData: {
    user_id: number;
    limit: number;
}) => {
    const { user_id, limit } = feedData;

    const result = await pool.query(
        `
  WITH tag_scores AS (
    SELECT 
      vt.video_id,
      COALESCE(SUM(utp.score), 0) AS tag_score
    FROM video_tags vt
    LEFT JOIN user_tag_preferences utp
      ON utp.tag_id = vt.tag_id
      AND utp.user_id = $2
    GROUP BY vt.video_id
  ),

  like_counts AS (
    SELECT 
      video_id,
      COUNT(*) AS like_count
    FROM likes
    GROUP BY video_id
  ),

  comment_counts AS (
    SELECT 
      video_id,
      COUNT(*) AS comment_count
    FROM comments
    GROUP BY video_id
  )

  SELECT 
    v.*,
    u.username,

    COALESCE(lc.like_count, 0)::INT AS like_count,
    COALESCE(cc.comment_count, 0)::INT AS comment_count,

    COALESCE(ts.tag_score, 0) * 10 AS tag_component,
    COALESCE(lc.like_count, 0) * 2 AS like_component,
    COALESCE(cc.comment_count, 0) AS comment_component,

    EXISTS (
      SELECT 1
      FROM likes l2
      WHERE l2.video_id = v.id
        AND l2.user_id = $2
    ) AS is_liked,

    COALESCE(ts.tag_score, 0) AS tag_score,

    (
      COALESCE(ts.tag_score, 0) * 10 +
      COALESCE(lc.like_count, 0) * 2 +
      COALESCE(cc.comment_count, 0) * 1 +
      CASE WHEN f.follower_id IS NOT NULL THEN 50 ELSE 0 END +
      (RANDOM() * 5) +
      10 * EXP(-EXTRACT(EPOCH FROM (NOW() - v.created_at)) / 172800) -- new videos gain 10 score, over 2 days decay to 0
    ) AS score

  FROM videos v

  LEFT JOIN users u ON v.user_id = u.id

  LEFT JOIN tag_scores ts ON ts.video_id = v.id
  LEFT JOIN like_counts lc ON lc.video_id = v.id
  LEFT JOIN comment_counts cc ON cc.video_id = v.id

  LEFT JOIN followers f 
    ON f.following_id = v.user_id 
    AND f.follower_id = $2


  ORDER BY score DESC
  LIMIT $1
  `,
        [limit, user_id],
    );

    return result.rows;
};

export const dbGetVideoById = async (id: number) => {
    const query = `
    SELECT 
        v.*,
        (SELECT COUNT(*) FROM likes l WHERE l.video_id = v.id)::INT AS like_count,
        (SELECT COUNT(*) FROM comments c WHERE c.video_id = v.id)::INT AS comment_count
    FROM videos v
    WHERE v.id = $1;`;
    const result: QueryResult<DB_VIDEO> = await pool.query(query, [id]);
    return result.rowCount ? result.rows[0] : null;
};

export const dbGetCommentsWithReplyCount = async (videoId: number) => {
const query = `
SELECT 
  c.*,
  u.username,
  COALESCE(rc.reply_count, 0)::INT AS reply_count
FROM comments c
LEFT JOIN users u
  ON u.id = c.user_id
LEFT JOIN (
  SELECT parent_comment_id, COUNT(*) AS reply_count
  FROM comments
  WHERE parent_comment_id IS NOT NULL
  GROUP BY parent_comment_id
) rc
  ON rc.parent_comment_id = c.id
WHERE c.video_id = $1
ORDER BY c.created_at DESC;
`

    const result = await pool.query(
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
    const result: QueryResult<DB_FOLLOWER> = await pool.query(query, [
        username,
    ]);
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

export const dbGetProfileData = async (profileData: {userId: Number, username: string}) => {
    const {userId, username} = profileData
    const query = `
    SELECT 
  u.id,
  u.username,

  (SELECT COUNT(*) 
   FROM followers 
   WHERE following_id = u.id)::INT AS follower_count,

  (SELECT COUNT(*) 
   FROM followers 
   WHERE follower_id = u.id)::INT AS following_count,

    EXISTS (
    SELECT 1
    FROM followers f
    WHERE f.follower_id = $2
      AND f.following_id = u.id
  ) AS is_followed,

  COALESCE(
    JSON_AGG(
      JSON_BUILD_OBJECT(
        'video_id', v.id,
        'title', v.title,
        'key', v.key,
        'description', v.description,
        'created_at', v.created_at
      )
    ) FILTER (WHERE v.id IS NOT NULL),
    '[]'
  ) AS videos

FROM users u
LEFT JOIN videos v 
  ON v.user_id = u.id

WHERE u.username = $1

GROUP BY u.id, u.username;`

    const result = await pool.query(query, [username, userId])
    if(result.rowCount) {
        console.log(result.rows[0])
    }
    return result.rowCount ? result.rows[0] : null
}
