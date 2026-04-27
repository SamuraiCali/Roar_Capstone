import { Router } from "express";
import { likeCommentHandler, likeVideo, unlikeCommentHandler, unlikeVideo } from "../controllers/likeController";

const router = Router();

router.post("/:videoId/likes", likeVideo);
router.delete("/:videoId/likes", unlikeVideo);

router.post("/comment/:commentId/like", likeCommentHandler)
router.delete("/comment/:commentId/like", unlikeCommentHandler)

export default router;
