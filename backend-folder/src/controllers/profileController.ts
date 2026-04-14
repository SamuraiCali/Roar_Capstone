import { Response } from "express";
import { AuthRequest } from "../routes/authMiddleware";
import { dbGetProfileData } from "../utils/dbUtils";

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

    const profileData = await dbGetProfileData({username: username as string, userId: Number(req.user.id)})

    if(!profileData) return res.status(404).json({error: "User not found"})

    res.json({ ...profileData });
  } catch (err) {
    console.log("Error while getting profile data: ", err);
    res.status(500).json({ error: "Internal Server Error" });
  }
    
}