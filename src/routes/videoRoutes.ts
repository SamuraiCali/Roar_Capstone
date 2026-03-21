import { Router } from "express";
import {
  getFeedHandler,
  getVideoUploadUrlHandler,
  postVideoHandler,
} from "../controllers/videoController";

const router = Router();

router.get("/presigned-url", getVideoUploadUrlHandler);
router.post("/", postVideoHandler);
router.get("/", getFeedHandler);
// router.get("/:id", getVideoById)

export default router;
