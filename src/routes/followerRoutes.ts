import { Router } from "express";
import {
  followUserHandler,
  getFollowersCountHandler,
  getFollowersHandler,
  unfollowHandler,
} from "../controllers/followerController";

const router = Router();

router.get("/:username/followers", getFollowersHandler);
router.get("/:username/followers/count", getFollowersCountHandler);
router.post("/:username/follow", followUserHandler);
router.delete("/:username/follow", unfollowHandler);

export default router;
