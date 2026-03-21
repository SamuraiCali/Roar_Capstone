import { Request, Response } from "express";
import {
  dbGetCommentsWithReplyCount,
  dbCreateComment,
  dbGetCommentById,
  dbDeleteCommentById,
} from "../utils/dbUtils";

export const postCommentHandler = async (req: Request, res: Response) => {
  try {
    const videoId = req.params.videoId;
    const { user_id, content, parent_comment_id } = req.body;

    if (!videoId || !user_id || !content) {
      return res.status(400).json({
        error: "Missing comment information (video ID, user ID, or content)",
      });
    }

    if (parent_comment_id) {
      const parent = await dbGetCommentById(parent_comment_id);

      if (!parent) {
        return res.status(404).json({ error: "Parent comment not found" });
      }

      if (parent.video_id !== Number(videoId)) {
        return res
          .status(400)
          .json({ error: "Invalid parent comment (different video)" });
      }

      if (parent.parent_comment_id !== null) {
        return res.status(400).json({ error: "Cannot reply to a reply" });
      }
    }

    const result = await dbCreateComment({
      user_id: user_id,
      video_id: Number(videoId),
      content: content,
      parent_comment_id: parent_comment_id,
    });

    res.status(201).json({ comment: result });
  } catch (err) {
    console.log("Error while posting comment: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getCommentsHandler = async (req: Request, res: Response) => {
  try {
    const videoId = req.params.videoId;

    if (!videoId) {
      res.status(400).json({ error: "Video ID required" });
      return;
    }

    const comments = await dbGetCommentsWithReplyCount(Number(videoId));
    res.status(200).json({ comments: comments });
  } catch (err) {
    console.log("Error while fetching comment: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const deleteCommentHandler = async (req: Request, res: Response) => {
  try {
    const { comment_id } = req.body;
    if (!comment_id) {
      return res.status(400).json({ error: "Comment ID required" });
    }

    const deleted = await dbDeleteCommentById(comment_id);

    if (deleted === 0) {
      return res.status(400).json({ error: "Invalid comment (doesn't exist)" });
    }

    res.status(200).json({ message: "Successfully deleted comment" });
  } catch (err) {
    console.log("Error while deleting comment: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
