import { likeVideo, unlikeVideo } from "../controllers/likeController";
import { dbCreateLike, dbDeleteLike } from "../utils/dbUtils";

jest.mock("../utils/dbUtils");

describe("likeController", () => {
    const mockRes = () => {
        const res: any = {};
        res.status = jest.fn().mockReturnValue(res);
        res.json = jest.fn().mockReturnValue(res);
        return res;
    };

    //=================
    //likeVideo Tests
    //=================
    describe("likeVideo", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = {
                user: null,
                params: { videoId: "1" },
            };
            const res = mockRes();

            await likeVideo(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if missing user_id or videoId", async () => {
            const req: any = {
                user: { id: "" },
                params: { videoId: "" },
            };
            const res = mockRes();

            await likeVideo(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "user_id and videoId required",
            });
        });

        it("should call dbCreateLike and return result", async () => {
            const mockLike = { id: 1, userId: 1, videoId: 10 };
            (dbCreateLike as jest.Mock).mockResolvedValue(mockLike);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await likeVideo(req, res);

            expect(dbCreateLike).toHaveBeenCalledWith({
                userId: 1,
                videoId: 10,
            });

            expect(res.json).toHaveBeenCalledWith({
                like: mockLike,
            });
        });

        it("should handle database errors", async () => {
            (dbCreateLike as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await likeVideo(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });

    //=========================
    //unlikeVideo Tests
    //=========================

    describe("unlikeVideo", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = { user: null, params: { videoId: "1" } };
            const res = mockRes();

            await unlikeVideo(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
        });

        it("should return 400 if missing user_id or videoId", async () => {
            const req: any = {
                user: { id: "" },
                params: { videoId: "" },
            };
            const res = mockRes();

            await unlikeVideo(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "videoId and user_id required",
            });
        });

        it("should return 404 if like does not exist", async () => {
            (dbDeleteLike as jest.Mock).mockResolvedValue(0);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await unlikeVideo(req, res);

            expect(dbDeleteLike).toHaveBeenCalledWith({
                userId: 1,
                videoId: 10,
            });

            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({
                error: "Like does not exist",
            });
        });

        it("should successfully unlike a video", async () => {
            (dbDeleteLike as jest.Mock).mockResolvedValue(1);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await unlikeVideo(req, res);

            expect(dbDeleteLike).toHaveBeenCalledWith({
                userId: 1,
                videoId: 10,
            });

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: "Video successfully unliked",
            });
        });

        it("should handle database errors", async () => {
            (dbDeleteLike as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await unlikeVideo(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });
});
