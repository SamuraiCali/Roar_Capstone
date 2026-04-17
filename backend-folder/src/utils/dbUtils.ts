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

export const sportMap: Record<string, number> = {
    basketball: 1,
    volleyball: 2,
    baseball: 3,
    soccer: 4,
    football: 5,
    other: 6
};

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
    title: string
    description: string | null;
    sport: string
    duration_seconds: number | null;
    width: number | null;
    height: number | null;
}
export const dbCreateVideo = async (videoData: videoData) => {
    const {
        user_id,
        key,
        title,
        description = null,
        sport,
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

     const newQuery = `
   WITH base AS (
  SELECT 
    v.*,
    RANDOM() * 10 AS rand
  FROM videos v
),

tag_scores AS (
  SELECT 
    vt.video_id,
    COALESCE(AVG(utp.score), 0) AS tag_score
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
  b.*,
  u.username,
  u.profile_image_key,

  COALESCE(lc.like_count, 0)::INT AS like_count,
  COALESCE(cc.comment_count, 0)::INT AS comment_count,

  EXISTS (
    SELECT 1
    FROM likes l2
    WHERE l2.video_id = b.id
      AND l2.user_id = $2
  ) AS is_liked,

  -- 🔍 Raw tag score
  COALESCE(ts.tag_score, 0)::FLOAT AS tag_score,

  -- =========================
  -- 🎯 COMPONENTS (DEBUG)
  -- =========================

  -- Tag relevance (capped)
  LEAST(COALESCE(ts.tag_score, 0), 5) * 15 AS tag_component,

  -- Engagement (log scaled)
  LOG(1 + COALESCE(lc.like_count, 0)) * 20 AS like_component,
  LOG(1 + COALESCE(cc.comment_count, 0)) * 10 AS comment_component,

  -- Social
  CASE 
    WHEN f.follower_id IS NOT NULL THEN 30 
    ELSE 0 
  END AS follower_component,

  -- Recency boost (early push)
  120 * EXP(-EXTRACT(EPOCH FROM (NOW() - b.created_at)) / 86400) 
    AS recency_component,

  -- Random (shared)
  b.rand AS random_component,

  -- Global decay
  EXP(-EXTRACT(EPOCH FROM (NOW() - b.created_at)) / 604800) 
    AS decay_multiplier,

  -- =========================
  -- 🧠 FINAL SCORE
  -- =========================

  (
    (
      LEAST(COALESCE(ts.tag_score, 0), 5) * 15 +

      LOG(1 + COALESCE(lc.like_count, 0)) * 20 +
      LOG(1 + COALESCE(cc.comment_count, 0)) * 10 +

      CASE 
        WHEN f.follower_id IS NOT NULL THEN 30 
        ELSE 0 
      END +

      120 * EXP(-EXTRACT(EPOCH FROM (NOW() - b.created_at)) / 86400) +

      b.rand
    )
    *
    EXP(-EXTRACT(EPOCH FROM (NOW() - b.created_at)) / 604800)
  ) AS score

FROM base b

LEFT JOIN users u ON b.user_id = u.id
LEFT JOIN tag_scores ts ON ts.video_id = b.id
LEFT JOIN like_counts lc ON lc.video_id = b.id
LEFT JOIN comment_counts cc ON cc.video_id = b.id

LEFT JOIN followers f 
  ON f.following_id = b.user_id 
  AND f.follower_id = $2

ORDER BY score DESC
LIMIT $1;
    `

    const oldQuery = 
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
    u.profile_image_key,

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
      50 * EXP(-EXTRACT(EPOCH FROM (NOW() - v.created_at)) / 172800) -- new videos gain 10 score, over 2 days decay to 0
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
  `

    const result = await pool.query(newQuery, [limit, user_id]);

    return result.rows;
};

export const dbGetFriendsFeedVideos = async (feedData: {
    user_id: number;
    limit: number;
}) => {
    const { user_id, limit } = feedData;

    const query =        `
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
    u.profile_image_key,

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
      (RANDOM() * 5) +
      10 * EXP(-EXTRACT(EPOCH FROM (NOW() - v.created_at)) / 172800)
    ) AS score

  FROM videos v

  JOIN users u 
    ON v.user_id = u.id

  JOIN followers f 
    ON f.following_id = v.user_id 
    AND f.follower_id = $2

  LEFT JOIN tag_scores ts ON ts.video_id = v.id
  LEFT JOIN like_counts lc ON lc.video_id = v.id
  LEFT JOIN comment_counts cc ON cc.video_id = v.id

  ORDER BY score DESC
  LIMIT $1
  `

    console.log("New query")
    const result = await pool.query(query, [limit, user_id]);

    return result.rows;
};

export const dbGetUsersVideos = async (feedData: {
    current_user_id: number;
    target_user_id: number;
    limit: number;
}) => {
    const { current_user_id, target_user_id, limit } = feedData;

    const result = await pool.query(
        `
        SELECT 
        v.*,
        u.username,
        u.profile_image_key,

        COALESCE(lc.like_count, 0)::INT AS like_count,
        COALESCE(cc.comment_count, 0)::INT AS comment_count,

        EXISTS (
            SELECT 1
            FROM likes l2
            WHERE l2.video_id = v.id
            AND l2.user_id = $3
        ) AS is_liked

        FROM videos v

        JOIN users u 
        ON v.user_id = u.id

        LEFT JOIN (
        SELECT video_id, COUNT(*) AS like_count
        FROM likes
        GROUP BY video_id
        ) lc ON lc.video_id = v.id

        LEFT JOIN (
        SELECT video_id, COUNT(*) AS comment_count
        FROM comments
        GROUP BY video_id
        ) cc ON cc.video_id = v.id

        WHERE v.user_id = $2

        ORDER BY v.created_at DESC
        LIMIT $1;

  `,
        [limit, target_user_id, current_user_id],
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

export const dbGetEnrichedComments = async (commentData: {userId: number, videoId: number}) => {
    const {userId, videoId} = commentData
// const query = `
// SELECT 
//   c.*,
//   u.username,
//   COALESCE(rc.reply_count, 0)::INT AS reply_count
// FROM comments c
// LEFT JOIN users u
//   ON u.id = c.user_id
// LEFT JOIN (
//   SELECT parent_comment_id, COUNT(*) AS reply_count
//   FROM comments
//   WHERE parent_comment_id IS NOT NULL
//   GROUP BY parent_comment_id
// ) rc
//   ON rc.parent_comment_id = c.id
// WHERE c.video_id = $1
// ORDER BY c.created_at DESC;
// `
const query = `
SELECT 
  c.*,
  u.username,
  u.profile_image_key,
  COALESCE(rc.reply_count, 0)::INT AS reply_count,
  COALESCE(lc.like_count, 0)::INT AS like_count,
  (cl_user.user_id IS NOT NULL) AS is_liked

FROM comments c

LEFT JOIN users u
  ON u.id = c.user_id

-- reply count
LEFT JOIN (
  SELECT parent_comment_id, COUNT(*) AS reply_count
  FROM comments
  WHERE parent_comment_id IS NOT NULL
  GROUP BY parent_comment_id
) rc
  ON rc.parent_comment_id = c.id

-- like count
LEFT JOIN (
  SELECT comment_id, COUNT(*) AS like_count
  FROM comment_likes
  GROUP BY comment_id
) lc
  ON lc.comment_id = c.id

-- whether current user liked it
LEFT JOIN comment_likes cl_user
  ON cl_user.comment_id = c.id
  AND cl_user.user_id = $2

WHERE c.video_id = $1

ORDER BY c.created_at DESC;
`

    const result = await pool.query(
        query,
        [videoId, userId],
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
  u.profile_image_key,

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
    return result.rowCount ? result.rows[0] : null
}

export const dbCreateCommentLike = async (likeData: {userId: number, commentId: number}) => {
    const {userId, commentId} = likeData
    const query = "INSERT INTO comment_likes (user_id, comment_id) VALUES ($1, $2) ON CONFLICT DO NOTHING;"
    await pool.query(query, [userId, commentId])
}

export const dbDeleteCommentLike = async (likeData: {userId: number, commentId: number}) => {
    const {userId, commentId} = likeData
    const query = "DELETE FROM comment_likes WHERE user_id = $1 AND comment_id = $2"
    await pool.query(query, [userId, commentId])
}

export const dbUpdateUserWithProfileImageKey = async (profileData: {userId: Number, key: string}) => {
    const {userId, key} = profileData
    const query = "UPDATE USERS SET profile_image_key = $1 WHERE id = $2"
    await pool.query(query, [key, userId])
}

type DB_PFP = {
    profile_image_key: string | null
}
export const dbGetProfileImageKeyForUser = async (userId: number) => {
  try {
    const result: QueryResult<DB_PFP> = await pool.query("SELECT profile_image_key FROM users WHERE id = $1", [userId])
    return result.rowCount ? result.rows[0]?.profile_image_key : null

  } catch(err) {
    console.log(`Error getting user profile image key: ${err}`)
  }
}

export const dbCreateUserTagPreference = async (tagData: {userId: number, sport: string}) => {
    const {userId, sport} = tagData
    // const sportMap: Record<string, number> = {
    //     basketball: 1,
    //     volleyball: 2,
    //     baseball: 3,
    //     soccer: 4,
    //     football: 5,
    //     other: 6
    // };
    if(!(sport in sportMap)) {
        console.log(`sport ${sport} not in map`)
        throw new Error(`Invalid sport: ${sport}`)

    }
    console.log(`Creating tag pref for ${sport}: ${sportMap[sport]}`)
    const query = "INSERT INTO user_tag_preferences (user_id, tag_id, score) VALUES ($1, $2, $3)"
    await pool.query(query, [userId, sportMap[sport], 10])
}
