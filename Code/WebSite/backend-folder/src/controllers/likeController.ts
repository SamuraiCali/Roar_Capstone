import { Request, Response } from "express";
import { dbCreateLike, dbDeleteLike } from "../utils/dbUtils";
import { AuthRequest } from "../routes/authMiddleware";

export const likeVideo = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    const user_id = Number(req.user.id);
    const videoId = req.params.videoId;

    if (!user_id || !videoId) {
      res.status(400).json({ error: "user_id and videoId required" });
      return;
    }

    const likeResult = await dbCreateLike({
      userId: user_id,
      videoId: Number(videoId),
    });
    res.json({ like: likeResult });
  } catch (err) {
    console.log("Error while liking video: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const unlikeVideo = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized" });
    }

    const user_id = Number(req.user.id);
    const videoId = req.params.videoId;

    if (!videoId || !user_id) {
      res.status(400).json({ error: "videoId and user_id required" });
      return;
    }

    const deleted = await dbDeleteLike({
      userId: user_id,
      videoId: Number(videoId),
    });
    if (deleted === 0) {
      res.status(404).json({ error: "Like does not exist" });
      return;
    }
    res.status(200).json({ message: "Video successfully unliked" });
  } catch (err) {
    console.log("Error while unliking video: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
