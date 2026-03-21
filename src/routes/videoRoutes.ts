import { Router } from "express";
import {
  getFeed,
  getPresignedUploadUrl,
  saveVideoKey,
} from "../controllers/videoController";

const router = Router();

router.get("/presigned-url", getPresignedUploadUrl);
router.post("/", saveVideoKey);
router.get("/", getFeed);
// router.get("/:id", getVideoById)

export default router;
