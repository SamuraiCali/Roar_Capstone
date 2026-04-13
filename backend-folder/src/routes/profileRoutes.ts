import { Router } from "express";
import { getProfileHandler } from "../controllers/profileController";


const router = Router();

router.get("/:username", getProfileHandler);

export default router;