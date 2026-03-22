import { Response } from "express";
import { AuthRequest } from "../routes/authMiddleware";
import {
  dbCreateFollow,
  dbDeleteFollow,
  dbGetFollowersCountFromUsername,
  dbGetFollowersFromUsername,
  dbGetUserByUsername,
} from "../utils/dbUtils";

export const getFollowersHandler = async (req: AuthRequest, res: Response) => {
  try {
    const username = req.params.username;

    if (!username) {
      return res.status(400).json({ error: "Username required" });
    }

    const followers = await dbGetFollowersFromUsername(username as string);
    res.status(200).json({ followers: followers });
  } catch (err) {
    console.log("Error while fetching followers: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const getFollowersCountHandler = async (
  req: AuthRequest,
  res: Response,
) => {
  try {
    const username = req.params.username;
    if (!username) {
      return res.status(400).json({ error: "Username required" });
    }
    const followerCount = await dbGetFollowersCountFromUsername(
      username as string,
    );
    console.log(`Attempting to get follower account for user ${username}`);
    res.status(200).json({ follower_count: followerCount });
  } catch (err) {
    console.log("Error while fetching followers: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const followUserHandler = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(400).json({ error: "Unauthorized" });
    }

    if (!req.params.username) {
      return res.status(400).json({ error: "Username required" });
    }

    const user_id = Number(req.user.id);
    const following_username = req.params.username as string;

    if (following_username === req.user.username) {
      return res.status(400).json({ error: "Cannot follow self" });
    }

    const result = await dbCreateFollow({
      follower_id: user_id,
      following_username: following_username,
    });

    if (result.rowCount! > 0)
      return res.status(200).json({ follow: result.rows[0] });

    const userCheck = await dbGetUserByUsername(following_username);

    if (userCheck.rowCount === 0)
      return res.status(404).json({ error: "User not found" });

    return res.status(400).json({ error: "Already following this user" });
  } catch (err: any) {
    if (err.code === "23505") {
      return res.status(400).json({ error: "You already follow this user" });
    }
    console.log("Error while fetching followers: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};

export const unfollowHandler = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(400).json({ error: "Unauthorized" });
    }

    if (!req.params.username) {
      return res.status(400).json({ error: "Username required" });
    }

    const user_id = Number(req.user.id);
    const following_username = req.params.username as string;

    if (following_username === req.user.username) {
      return res.status(400).json({ error: "Cannot unfollow self" });
    }

    const deleted = await dbDeleteFollow({
      follower_id: user_id,
      following_username: following_username,
    });
    if (deleted === 0) {
      return res.status(404).json({ error: "Follow relationship not found" });
    }
    res
      .status(200)
      .json({ message: "Successfully unfollowed user " + following_username });
  } catch (err) {
    console.log("Error while fetching followers: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
};
