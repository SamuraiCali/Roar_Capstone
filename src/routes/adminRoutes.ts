import { Router } from "express";
import {
  getCommentsAdmin,
  getLikesAdmin,
  getUsersAdmin,
  getVideosAdmin,
} from "../controllers/adminController";

const router = Router();

router.get("/users", getUsersAdmin);
router.get("/videos", getVideosAdmin);
router.get("/likes", getLikesAdmin);
router.get("/comments", getCommentsAdmin);

export default router;
