import { Router } from "express";
import { getProfileHandler, getProfileImageUploadUrlHandler, saveBioHandler, saveProfileImageHandler } from "../controllers/profileController";


const router = Router();

router.get("/:username", getProfileHandler);
router.post("/avatar", getProfileImageUploadUrlHandler)
router.post("/avatar/save", saveProfileImageHandler)
router.post("/bio", saveBioHandler)

export default router;