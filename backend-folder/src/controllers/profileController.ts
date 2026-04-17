import { Response } from "express";
import { AuthRequest } from "../routes/authMiddleware";
import { dbGetProfileData, dbUpdateUserWithBio, dbUpdateUserWithProfileImageKey } from "../utils/dbUtils";
import { getPresignedUploadUrlHelper } from "../utils/S3Utils";

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

export const getProfileImageUploadUrlHandler = async (req: AuthRequest, res: Response) => {
    try {
        const { fileName, fileType } = req.query;

        if (!fileName || !fileType) {
            return res
                .status(400)
                .json({ error: "Missing fileName or fileType" });
        }

        const type = String(fileType);

        if (!type.startsWith("image/")) {
            return res.status(400).json({ error: "Invalid file type" });
        }

        const allowedTypes = ["image/jpeg", "image/png", "image/webp"];
        if (!allowedTypes.includes(type)) {
            return res.status(400).json({ error: "Unsupported image format" });
        }

        const userId = req.user?.id;
        if (!userId) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        // Normalize filename (prevent weird chars)
        const safeFileName = String(fileName).replace(/[^a-zA-Z0-9.\-_]/g, "");

        // OPTION A: Stable key (overwrite previous avatar)
        const key = `profile-images/${userId}/avatar.${safeFileName.split(".").pop()}`;

        const url = await getPresignedUploadUrlHelper(key, type, {
            cacheControl: "public, max-age=31536000",
        });

        // publicUrl: `https://${process.env.S3_BUCKET}.s3.amazonaws.com/${key}`,


        res.json({
            uploadUrl: url,
            key: key
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Failed to generate pre-signed URL" });
    }
};

export const saveProfileImageHandler = async (req: AuthRequest, res: Response) => {
    try {

        if (!req.user) {
            return res.status(401).json({ error: "Unauthorized" });
        }

        const {key} = req.query

        if(!key) return res.status(400).json({error: "Missing Key"})

        await dbUpdateUserWithProfileImageKey({userId: Number(req.user.id), key: key as string})

        res.status(200).json({});
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Internal server error" });
    }
};

export const saveBioHandler = async (req: AuthRequest, res: Response) => {
    try {

        if (!req.user) {
            return res.status(401).json({ error: "Unauthorized" });
        }


        const {bio} = req.body

        if(typeof(bio) !== "string") return res.status(400).json({error: "Bio must be of type string"})
        
        if(bio.length > 50) return res.status(400).json({error: "Bio exceeds character limit (50)"})

        await dbUpdateUserWithBio({userId: Number(req.user.id), bio: bio})

        console.log("Successfully updated user's bio.")

        res.status(200).json({});
    } catch (err) {
        console.error(err);
        res.status(500).json({ error: "Internal server error" });
    }
};