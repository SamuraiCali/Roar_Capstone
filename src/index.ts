// Import dependencies
import dotenv from "dotenv";
dotenv.config({ override: true });

import express from "express";
import type { Request, Response } from "express";
import videoRoutes from "./routes/videoRoutes";
import { setupDB } from "./config/setupDB";

// Initialize app
const app = express();

// Set port
// const PORT = 3000;
const PORT = process.env.PORT;

// Middleware (optional)
app.use(express.json());

// Basic GET route
app.get("/api/example", (req: Request, res: Response) => {
  res.status(200).json({
    message: "GET request successful! ok",
    data: [],
  });
});

app.use("/api/videos", videoRoutes);

console.log(`BUCKET NAME: ${process.env.S3_BUCKET_NAME}`);

// Start server
const startServer = async () => {
  // await setupDB();

  app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}!!`);
  });
};

startServer();
