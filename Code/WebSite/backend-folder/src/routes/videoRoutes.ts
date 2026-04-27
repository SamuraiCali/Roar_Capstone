import { Router } from "express";
import {
    getFeedHandler,
    getFriendsFeedHandler,
    getUsersVideosHandler,
    getVideoHandler,
    getVideoUploadUrlHandler,
    uploadVideoHandler,
} from "../controllers/videoController";

const router = Router();

router.get("/presigned-url", getVideoUploadUrlHandler);
// router.post("/", postVideoHandler);
router.post("/", uploadVideoHandler);

router.get("/", getFeedHandler);
router.get("/friends", getFriendsFeedHandler)
router.get("/user/:userId", getUsersVideosHandler)
router.get("/:videoId", getVideoHandler);

export default router;
