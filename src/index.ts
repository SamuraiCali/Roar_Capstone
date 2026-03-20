// Import dependencies
import dotenv from "dotenv";
dotenv.config({ override: true });

import express from "express";
import type { Request, Response } from "express";
import videoRoutes from "./routes/videoRoutes";
import authRoutes from "./routes/authRoutes";
import { setupDB } from "./config/setupDB";

const app = express();

const PORT = process.env.PORT;

app.use(express.json());

app.get("/api/example", (req: Request, res: Response) => {
  res.status(200).json({
    message: "GET request successful! ok",
  });
});

app.use("/api/videos", videoRoutes);
app.use("/api/auth", authRoutes);

console.log(`BUCKET NAME: ${process.env.S3_BUCKET_NAME}`);

// Start server
const startServer = async () => {
  await setupDB();

  app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}!`);
  });
};

startServer();
