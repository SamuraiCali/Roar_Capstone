import { Router } from "express";
import { likeVideo, unlikeVideo } from "../controllers/likeController";

const router = Router();

router.post("/:videoId/likes", likeVideo);
router.delete("/:videoId/likes", unlikeVideo);

export default router;
