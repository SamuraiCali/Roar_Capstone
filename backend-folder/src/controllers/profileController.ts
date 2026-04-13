import { Response } from "express";
import { AuthRequest } from "../routes/authMiddleware";
import { dbGetProfileDataFromUsername } from "../utils/dbUtils";

export const getProfileHandler = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ error: "Unauthorized" });
    }
    // const user_id = Number(req.user.id);
    const username = req.params.username;

    if (!username) {
      res.status(400).json({ error: "username required" });
      return;
    }

    console.log("attempting to get profile data onn ", username)


    const profileData = await dbGetProfileDataFromUsername(username as string)

    if(!profileData) return res.status(404).json({error: "User not found"})

    // const likeResult = await dbCreateLike({
    //   userId: user_id,
    //   videoId: Number(videoId),
    // });
    res.json({ ...profileData });
  } catch (err) {
    console.log("Error while getting profile data: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
    
}