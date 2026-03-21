import { Router } from "express";
import {
  deleteCommentHandler,
  getCommentsHandler,
  postCommentHandler,
} from "../controllers/commentController";

const router = Router();

router.get("/:videoId/comments", getCommentsHandler);
router.post("/:videoId/comments", postCommentHandler);
router.delete("/:videoId/comments", deleteCommentHandler);

export default router;
