import { Request, Response } from "express";
import {
    dbCreateVideo,
    dbGetFeedVideos,
    dbGetFriendsFeedVideos,
    dbGetUsersVideos,
    dbGetVideoById,
} from "../utils/dbUtils";
import {
    getPresignedDownloadUrl,
    getPresignedUploadUrlHelper,
} from "../utils/S3Utils";
import { AuthRequest } from "../routes/authMiddleware";

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

export const postVideoHandler = async (req: AuthRequest, res: Response) => {
    try {
        const { key, title, description, duration_seconds, width, height } =
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
            console.log(`get users videos handler`)

    if (!req.user) {
        return res.status(401).json({ error: "Unauthorized" });
    }

    const user_id = req.params.userId

    if (!user_id) return res.status(400).json({ error: "User ID Required" });
    

    try {
        const videosFromDb = await dbGetUsersVideos({
            user_id: Number(user_id),
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

        console.log(`videos: ${videos}`)

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
