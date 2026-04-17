import { Request, Response } from "express";
import {
    dbCreateVideo,
    dbGetFeedVideos,
    dbGetFriendsFeedVideos,
    dbGetUsersVideos,
    dbGetVideoById,
    sportMap,
} from "../utils/dbUtils";
import {
    getPresignedDownloadUrl,
    getPresignedUploadUrlHelper,
} from "../utils/S3Utils";
import { pool } from "../config/db";
import { AuthRequest } from "../routes/authMiddleware";
import { UploadVideoRequest } from "../models/RequestTypes";

export const getVideoUploadUrlHandler = async (req: Request, res: Response) => {
    try {
        const { fileName, fileType } = req.query;

        if (!fileName || !fileType) {
            return res
                .status(400)
                .json({ error: "Missing fileName or fileType" });
        }

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

export const uploadVideoHandler = async (req: AuthRequest, res: Response) => {
  const client = await pool.connect();

  try {

    const { key, description, sports}: UploadVideoRequest = req.body;

    if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const user_id = Number(req.user.id);

    // Basic validation
    if (!user_id || !key) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const hashtags = sports.map(sport => `#${sport}`).join(" ")
    console.log(`hashtags: ${hashtags} from ${sports}`)

    await client.query('BEGIN');

    //yes hashtags is title
    // 1. Insert video and get ID
    const videoResult = await client.query(
      `INSERT INTO videos (user_id, key, title, description)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [user_id, key, hashtags, description]
    );
    console.log(`UploadVideo: created video at id ${videoResult.rows[0].id}`)

    const videoId = videoResult.rows[0].id;

    // 2. Insert tags (if any) using UNNEST
    if (Array.isArray(sports) && sports.length > 0) {
        const tagIds = sports.map(sport => sportMap[sport])
        console.log(`Converting ${sports} to ${tagIds}`)
      await client.query(
        `INSERT INTO video_tags (video_id, tag_id)
         SELECT $1, UNNEST($2::int[])
         ON CONFLICT DO NOTHING`,
        [videoId, tagIds]
      );
    }

    await client.query('COMMIT');

    return res.status(201).json({
      video: videoResult.rows[0],
    });

  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Upload video error:', err);

    return res.status(500).json({
      error: 'Failed to upload video',
    });

  } finally {
    client.release();
  }
}

export const postVideoHandler = async (req: AuthRequest, res: Response) => {
    try {
        const { key, title, description, sport, duration_seconds, width, height } =
            req.body;

        if (!req.user) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        const user_id = Number(req.user.id);

        if (!key || !user_id) {
            return res
                .status(400)
                .json({ error: "key and user_id are required" });
        }

        const videoData = { user_id, ...req.body };
        const savedVideo = await dbCreateVideo(videoData);

        res.status(201).json({ video: savedVideo });
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
        const videosFromDb = await dbGetFeedVideos({
            user_id: user_id,
            limit: 10,
        });

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

export const getFriendsFeedHandler = async (req: AuthRequest, res: Response) => {
    if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const user_id = Number(req.user.id);

    if (!user_id) {
        return res.status(400).json({ error: "User ID Required" });
    }

    try {
        const videosFromDb = await dbGetFriendsFeedVideos({
            user_id: user_id,
            limit: 5,
        });

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
        console.log("Error fetching friends feed: ", err);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

export const getUsersVideosHandler = async (req: AuthRequest, res: Response) => {
    if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const target_user_id = req.params.userId

    if (!target_user_id) return res.status(400).json({ error: "Target User ID Required" });
    

    try {
        const videosFromDb = await dbGetUsersVideos({
            current_user_id: Number(req.user.id),
            target_user_id: Number(target_user_id),
            limit: 20,
        });

        if (!videosFromDb.length) {
            res.status(200).json([]);
            return;
        }

        const videos = await Promise.all(
            videosFromDb.map(async (video) => {
                const url = await getPresignedDownloadUrl(video.key);
                return { ...video, url: url };
            }),
        );

        res.status(200).json(videos ?? []);
    } catch (err) {
        console.log("Error fetching friends feed: ", err);
        res.status(500).json({ error: "Internal Server Error" });
    }
};

export const getVideoHandler = async (req: AuthRequest, res: Response) => {
    try {
        if (!req.user) return res.status(401).json({ error: "Unauthorized" });

        const user_id = Number(req.user.id);
        if (!user_id)
            return res.status(400).json({ error: "User ID Required" });

        const video_id = req.params.videoId;
        if (!video_id)
            return res
                .status(400)
                .json({ error: "Invalid URL: Missing Video ID" });

        const video = await dbGetVideoById(Number(video_id));
        if (!video)
            return res.status(404).json({ error: "Video Doesn't Exist" });

        const downloadUrl = await getPresignedDownloadUrl(video.key);
                res.status(200).json({ url: downloadUrl, ...video } );

        // res.status(200).json({ video: { url: downloadUrl, ...video } });
    } catch (err) {
        console.log(err);
        res.status(500).json({ error: "Internal Server Error" });
    }
};
