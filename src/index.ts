// Import dependencies
import dotenv from "dotenv";
dotenv.config({ override: true });

import express from "express";
import cookieParser from "cookie-parser";
import type { Request, Response } from "express";
import videoRoutes from "./routes/videoRoutes";
import authRoutes from "./routes/authRoutes";
import { testDatabaseConnection } from "./config/setupDB";
import { auth, AuthRequest } from "./routes/authMiddleware";

const app = express();

const PORT = process.env.PORT;

app.use(express.json());
app.use(cookieParser());

app.get("/api/example", (req: Request, res: Response) => {
  res.status(200).json({
    message: "GET request successful! ok",
  });
});

app.get("/api/protected", auth, (req: AuthRequest, res) => {
  res.json({ message: "You are authenticated", user: req.user });
});

app.use("/api/videos", videoRoutes);
app.use("/api/auth", authRoutes);

console.log(`BUCKET NAME: ${process.env.S3_BUCKET_NAME}`);

// Start server
const startServer = async () => {
  await testDatabaseConnection();

  app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}!`);
  });
};

startServer();
