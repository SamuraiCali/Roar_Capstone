import { Router } from "express";
import {
    getFeedHandler,
    getFriendsFeedHandler,
    getVideoHandler,
    getVideoUploadUrlHandler,
    postVideoHandler,
} from "../controllers/videoController";

const router = Router();

router.get("/presigned-url", getVideoUploadUrlHandler);
router.post("/", postVideoHandler);
router.get("/", getFeedHandler);
router.get("/friends", getFriendsFeedHandler)
router.get("/:videoId", getVideoHandler);

export default router;
