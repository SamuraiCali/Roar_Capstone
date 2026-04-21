import { Router } from "express";
import {
    getFeedHandler,
    getVideoHandler,
    getVideoUploadUrlHandler,
    postVideoHandler,
} from "../controllers/videoController";

const router = Router();

router.get("/presigned-url", getVideoUploadUrlHandler);
router.post("/", postVideoHandler);
router.get("/", getFeedHandler);
router.get("/:videoId", getVideoHandler);

export default router;
