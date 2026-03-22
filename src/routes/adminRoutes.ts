import { Router } from "express";
import {
  getCommentsAdmin,
  getFollowersAdmin,
  getLikesAdmin,
  getUsersAdmin,
  getVideosAdmin,
} from "../controllers/adminController";

const router = Router();

router.get("/users", getUsersAdmin);
router.get("/videos", getVideosAdmin);
router.get("/likes", getLikesAdmin);
router.get("/comments", getCommentsAdmin);
router.get("/followers", getFollowersAdmin);

export default router;
