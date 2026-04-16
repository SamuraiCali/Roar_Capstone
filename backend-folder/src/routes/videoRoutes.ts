import { Router } from "express";
import {
    getFeedHandler,
    getFriendsFeedHandler,
    getUsersVideosHandler,
    getVideoHandler,
    getVideoUploadUrlHandler,
    postVideoHandler,
} from "../controllers/videoController";

const router = Router();

router.get("/presigned-url", getVideoUploadUrlHandler);
router.post("/", postVideoHandler);
router.get("/", getFeedHandler);
router.get("/friends", getFriendsFeedHandler)
router.get("/user/:userId", getUsersVideosHandler)
router.get("/:videoId", getVideoHandler);

export default router;
