import { Router } from "express";
import { getProfileHandler, getProfileImageUploadUrlHandler, saveProfileImageHandler } from "../controllers/profileController";


const router = Router();

router.get("/:username", getProfileHandler);
router.post("/avatar", getProfileImageUploadUrlHandler)
router.post("/avatar/save", saveProfileImageHandler)

export default router;