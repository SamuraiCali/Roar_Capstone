import { Router } from "express";
import {
  getCommentLikesAdmin,
  getCommentsAdmin,
  getFollowersAdmin,
  getLikesAdmin,
  getTagsAdmin,
  getUsersAdmin,
  getUserTagPreferencesAdmin,
  getVideosAdmin,
  getVideoTagsAdmin,
} from "../controllers/adminController";

const router = Router();

router.get("/users", getUsersAdmin);
router.get("/videos", getVideosAdmin);
router.get("/likes", getLikesAdmin);
router.get("/comments", getCommentsAdmin);
router.get("/comment_likes", getCommentLikesAdmin);
router.get("/followers", getFollowersAdmin);
router.get("/tags", getTagsAdmin);
router.get("/video_tags", getVideoTagsAdmin);
router.get("/user_tag_preferences", getUserTagPreferencesAdmin);

export default router;
