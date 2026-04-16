// Import dependencies
import dotenv from "dotenv";
dotenv.config({ override: true });

import express from "express";
import cookieParser from "cookie-parser";
import type { Request, Response } from "express";
import videoRoutes from "./routes/videoRoutes";
import authRoutes from "./routes/authRoutes";
import likeRoutes from "./routes/likeRoutes";
import adminRoutes from "./routes/adminRoutes";
import commentRoutes from "./routes/commentRoutes";
import followerRoutes from "./routes/followerRoutes";
import profileRoutes from "./routes/profileRoutes"

import { testDatabaseConnection } from "./config/db";
import { auth, AuthRequest } from "./routes/authMiddleware";
import { dbGetProfileImageKeyForUser } from "./utils/dbUtils";

const app = express();

const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(cookieParser());

app.use((req, _, next) => {
    console.log("➡️ HIT:", req.method, req.url);
    next();
});

app.get("/api/example", (req: Request, res: Response) => {
  res.status(200).json({
    message: "GET request successful! ok",
  });
});

app.get("/api/protected", auth, async (req: AuthRequest, res) => {
  if(!req.user) return res.status(401).json({error: "Unauthenticated"})
  const key = await dbGetProfileImageKeyForUser(Number(req.user.id))
  res.json({ message: "You are authenticated", user: {imageKey: key, ...req.user} });
});

app.use("/api/videos", auth, videoRoutes);
app.use("/api/videos", auth, likeRoutes);
app.use("/api/videos", auth, commentRoutes);
app.use("/api/users", auth, followerRoutes);
app.use("/api/profile", auth, profileRoutes);

app.use("/api/auth", authRoutes);

app.use("/api/admin", adminRoutes);

console.log(`BUCKET NAME: ${process.env.S3_BUCKET_NAME}`);

const startServer = async () => {
  await testDatabaseConnection();
  // 192.168.1.87

  app.listen(Number(PORT), "0.0.0.0", () => {
  console.log(`Server is running on http://localhost:${PORT}!`);
});
}




startServer();
