import { Request, Response } from "express";
import { pool } from "../config/db";
import { dbGetFeedVideos } from "../utils/dbUtils";
import {
  getPresignedDownloadUrl,
  getPresignedUploadUrlHelper,
} from "../utils/S3Utils";
import { AuthRequest } from "../routes/authMiddleware";

export const getVideoUploadUrlHandler = async (req: Request, res: Response) => {
  try {
    const { fileName, fileType } = req.query;

    if (!fileName || !fileType) {
      return res.status(400).json({ error: "Missing fileName or fileType" });
    }

    //This may cause problems later VVV

    if (!(fileType as string).startsWith("video/")) {
      return res.status(400).json({ error: "Invalid file type" });
    }

    const key = `videos/${Date.now()}-${fileName}`;

    const url = await getPresignedUploadUrlHelper(key, String(fileType));

    res.json({
      uploadUrl: url,
      key: key,
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Failed to generate pre-signed URL" });
  }
};

export const postVideoHandler = async (req: AuthRequest, res: Response) => {
  try {
    const { key, title, description, duration_seconds, width, height } =
      req.body;

    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const user_id = Number(req.user.id);

    if (!key || !user_id) {
      return res.status(400).json({ error: "key and user_id are required" });
    }

    const query = `
      INSERT INTO videos (user_id, key, title, description, duration_seconds, width, height)
      VALUES ($1, $2, $3, $4, $5, $6, $7)
      RETURNING *;
    `;

    const values = [
      user_id,
      key,
      title || null,
      description || null,
      duration_seconds || null,
      width || null,
      height || null,
    ];

    const result = await pool.query(query, values);

    res.status(201).json({ video: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Internal server error" });
  }
};

export const getFeedHandler = async (req: AuthRequest, res: Response) => {
  if (!req.user) {
    return res.status(401).json({ error: "Unauthorized" });
  }

  const user_id = Number(req.user.id);

  if (!user_id) {
    return res.status(400).json({ error: "User ID Required" });
  }

  try {
    const videosFromDb = await dbGetFeedVideos({ user_id: user_id, limit: 3 });

    if (!videosFromDb.length) {
      res.status(200).json({ videos: [] });
      return;
    }

    const videos = await Promise.all(
      videosFromDb.map(async (video) => {
        const url = await getPresignedDownloadUrl(video.key);
        return { ...video, url: url };
      }),
    );

    res.status(200).json({ videos: videos });
  } catch (err) {
    console.log("Error fetching feed: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
