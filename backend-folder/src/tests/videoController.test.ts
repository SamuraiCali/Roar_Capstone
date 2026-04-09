jest.mock("../utils/S3Utils");
jest.mock("../utils/dbUtils");
import {
    getPresignedUploadUrlHelper,
    getPresignedDownloadUrl,
} from "../utils/S3Utils";
import {
    getVideoUploadUrlHandler,
    postVideoHandler,
    getFeedHandler,
    getVideoHandler,
} from "../controllers/videoController";
import {
    dbCreateVideo,
    dbGetFeedVideos,
    dbGetVideoById,
} from "../utils/dbUtils";

describe("videoController", () => {
    const mockRes = () => {
        const res: any = {};
        res.status = jest.fn().mockReturnValue(res);
        res.json = jest.fn().mockReturnValue(res);
        return res;
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    //==========================================
    //getVideoUploadUrlHanldler Tests
    //==========================================

    describe("getVideoUploadUrlHandler", () => {
        it("should return 400 if fileName or fileType is missing", async () => {
            const req: any = { query: {} };
            const res = mockRes();

            await getVideoUploadUrlHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Missing fileName or fileType",
            });
        });

        it("should return 400 if fileType is not a video", async () => {
            const req: any = {
                query: { fileName: "test.mp4", fileType: "image/png" },
            };
            const res = mockRes();

            await getVideoUploadUrlHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Invalid file type",
            });
        });

        it("should return an upload URL and key if inputs are valid", async () => {
            const fakeUrl = "https://fake-url.com";
            (getPresignedUploadUrlHelper as jest.Mock).mockResolvedValue(
                fakeUrl,
            );

            const mockTimestamp = 1234567890;
            jest.spyOn(global.Date, "now").mockReturnValue(mockTimestamp);

            const req: any = {
                query: { fileName: "video.mp4", fileType: "video/mp4" },
            };
            const res = mockRes();

            await getVideoUploadUrlHandler(req, res);

            const expectedKey = `videos/${mockTimestamp}-video.mp4`;

            expect(getPresignedUploadUrlHelper).toHaveBeenCalledWith(
                expectedKey,
                "video/mp4",
            );

            expect(res.json).toHaveBeenCalledWith(
                expect.objectContaining({
                    uploadUrl: fakeUrl,
                    key: expectedKey,
                }),
            );
        });

        it("should return 500 if helper throws an error", async () => {
            (getPresignedUploadUrlHelper as jest.Mock).mockRejectedValue(
                new Error("S3 error"),
            );

            const req: any = {
                query: { fileName: "video.mp4", fileType: "video/mp4" },
            };
            const res = mockRes();

            await getVideoUploadUrlHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Failed to generate pre-signed URL",
            });
        });
    });

    //==================================================
    //postVideoHandler Tests
    //==================================================
    describe("postVideoHandler", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = {
                user: null,
                body: { key: "abc123", title: "Test Video" },
            };
            const res = mockRes();

            await postVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if key is missing", async () => {
            const req: any = {
                user: { id: "1" },
                body: { title: "Test Video" },
            };
            const res = mockRes();

            await postVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "key and user_id are required",
            });
        });

        it("should call dbCreateVideo and return 201 with saved video", async () => {
            const fakeVideo = {
                id: 1,
                key: "abc123",
                title: "Test Video",
                user_id: 1,
            };
            (dbCreateVideo as jest.Mock).mockResolvedValue(fakeVideo);

            const req: any = {
                user: { id: "1" },
                body: {
                    key: "abc123",
                    title: "Test Video",
                    description: "desc",
                    duration_seconds: 120,
                    width: 1920,
                    height: 1080,
                },
            };
            const res = mockRes();

            await postVideoHandler(req, res);

            expect(dbCreateVideo).toHaveBeenCalledWith({
                user_id: 1,
                key: "abc123",
                title: "Test Video",
                description: "desc",
                duration_seconds: 120,
                width: 1920,
                height: 1080,
            });

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith({ video: fakeVideo });
        });

        it("should return 500 if dbCreateVideo throws an error", async () => {
            (dbCreateVideo as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1" },
                body: { key: "abc123", title: "Test Video" },
            };
            const res = mockRes();

            await postVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal server error",
            });
        });
    });

    //=====================================================
    //getFeedHandler Tests
    //=====================================================

    describe("getFeedHandler", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = { user: null };
            const res = mockRes();

            await getFeedHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if user_id is invalid", async () => {
            const req: any = { user: { id: "" } }; // invalid user ID
            const res = mockRes();

            await getFeedHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "User ID Required",
            });
        });

        it("should return empty array if no videos found", async () => {
            (dbGetFeedVideos as jest.Mock).mockResolvedValue([]);

            const req: any = { user: { id: "1" } };
            const res = mockRes();

            await getFeedHandler(req, res);

            expect(dbGetFeedVideos).toHaveBeenCalledWith({
                user_id: 1,
                limit: 5,
            });
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({ videos: [] });
        });

        it("should return videos with presigned URLs", async () => {
            const fakeVideos = [
                { id: 1, key: "video1.mp4", title: "Video 1" },
                { id: 2, key: "video2.mp4", title: "Video 2" },
            ];

            (dbGetFeedVideos as jest.Mock).mockResolvedValue(fakeVideos);
            (getPresignedDownloadUrl as jest.Mock).mockImplementation(
                async (key: string) => `https://fake-url.com/${key}`,
            );

            const req: any = { user: { id: "1" } };
            const res = mockRes();

            await getFeedHandler(req, res);

            expect(dbGetFeedVideos).toHaveBeenCalledWith({
                user_id: 1,
                limit: 5,
            });
            expect(getPresignedDownloadUrl).toHaveBeenCalledTimes(
                fakeVideos.length,
            );

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                videos: [
                    {
                        ...fakeVideos[0],
                        url: "https://fake-url.com/video1.mp4",
                    },
                    {
                        ...fakeVideos[1],
                        url: "https://fake-url.com/video2.mp4",
                    },
                ],
            });
        });

        it("should return 500 if dbGetFeedVideos throws an error", async () => {
            (dbGetFeedVideos as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = { user: { id: "1" } };
            const res = mockRes();

            await getFeedHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });

    //=====================================================
    //getVideoHandler Tests
    //=====================================================
    describe("getVideoHandler", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = { user: null };
            const res = mockRes();

            await getVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if user_id is invalid", async () => {
            const req: any = { user: { id: "" } };
            const res = mockRes();

            await getVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "User ID Required",
            });
        });

        it("should return 400 if videoId is missing", async () => {
            const req: any = { user: { id: "1" }, params: {} };
            const res = mockRes();

            await getVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Invalid URL: Missing Video ID",
            });
        });

        it("should return 404 if video does not exist", async () => {
            (dbGetVideoById as jest.Mock).mockResolvedValue(null);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await getVideoHandler(req, res);

            expect(dbGetVideoById).toHaveBeenCalledWith(10);
            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({
                error: "Video Doesn't Exist",
            });
        });

        it("should return video with download URL", async () => {
            const fakeVideo = {
                id: 10,
                key: "video.mp4",
                title: "Test Video",
            };

            (dbGetVideoById as jest.Mock).mockResolvedValue(fakeVideo);
            (getPresignedDownloadUrl as jest.Mock).mockResolvedValue(
                "https://fake-url.com/video.mp4",
            );

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await getVideoHandler(req, res);

            expect(dbGetVideoById).toHaveBeenCalledWith(10);
            expect(getPresignedDownloadUrl).toHaveBeenCalledWith("video.mp4");

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                video: {
                    url: "https://fake-url.com/video.mp4",
                    ...fakeVideo,
                },
            });
        });

        it("should return 500 if an error occurs", async () => {
            (dbGetVideoById as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
            };
            const res = mockRes();

            await getVideoHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });
});
