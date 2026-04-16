import {
    dbCreateComment,
    dbDeleteCommentById,
    dbGetCommentById
} from "../utils/dbUtils";
import {
    getCommentsHandler,
    postCommentHandler,
    deleteCommentHandler,
} from "../controllers/commentController";

jest.mock("../utils/dbUtils");

describe("commentController", () => {
    const mockRes = () => {
        const res: any = {};
        res.status = jest.fn().mockReturnValue(res);
        res.json = jest.fn().mockReturnValue(res);
        return res;
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    //===============================================
    //postCommentHandler Tests
    //===============================================
    describe("postCommentHandler", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = { user: null };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if required fields are missing", async () => {
            const req: any = {
                user: { id: "1" },
                params: { videoId: "" },
                body: { content: "" },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Missing comment information (video ID, user ID, or content)",
            });
        });

        it("should return 404 if parent comment does not exist", async () => {
            (dbGetCommentById as jest.Mock).mockResolvedValue(null);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
                body: { content: "reply", parent_comment_id: 5 },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(dbGetCommentById).toHaveBeenCalledWith(5);
            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({
                error: "Parent comment not found",
            });
        });

        it("should return 400 if parent comment belongs to different video", async () => {
            (dbGetCommentById as jest.Mock).mockResolvedValue({
                id: 5,
                video_id: 999, // different video
                parent_comment_id: null,
            });

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
                body: { content: "reply", parent_comment_id: 5 },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Invalid parent comment (different video)",
            });
        });

        it("should return 400 if trying to reply to a reply", async () => {
            (dbGetCommentById as jest.Mock).mockResolvedValue({
                id: 5,
                video_id: 10,
                parent_comment_id: 2, // already a reply
            });

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
                body: { content: "reply", parent_comment_id: 5 },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot reply to a reply",
            });
        });

        it("should create a comment successfully (no parent)", async () => {
            const fakeComment = { id: 1, content: "hello" };
            (dbCreateComment as jest.Mock).mockResolvedValue(fakeComment);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
                body: { content: "hello" },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(dbCreateComment).toHaveBeenCalledWith({
                user_id: 1,
                video_id: 10,
                content: "hello",
                parent_comment_id: undefined,
            });

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith({
                comment: fakeComment,
            });
        });

        it("should create a reply successfully", async () => {
            const fakeParent = {
                id: 5,
                video_id: 10,
                parent_comment_id: null,
            };

            const fakeComment = { id: 2, content: "reply" };

            (dbGetCommentById as jest.Mock).mockResolvedValue(fakeParent);
            (dbCreateComment as jest.Mock).mockResolvedValue(fakeComment);

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
                body: { content: "reply", parent_comment_id: 5 },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(dbCreateComment).toHaveBeenCalledWith({
                user_id: 1,
                video_id: 10,
                content: "reply",
                parent_comment_id: 5,
            });

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith({
                comment: fakeComment,
            });
        });

        it("should return 500 if dbCreateComment throws", async () => {
            (dbCreateComment as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1" },
                params: { videoId: "10" },
                body: { content: "hello" },
            };
            const res = mockRes();

            await postCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });

    //============================================
    //getCommentsHandler Tests
    //============================================

    describe("getCommentsHandler", () => {
        it("should return 400 if videoId is missing", async () => {
            const req: any = { params: {} };
            const res = mockRes();

            await getCommentsHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Video ID required",
            });
        });

    

    //============================================
    //deleteCommentsHandler Tests
    //============================================
    describe("deleteCommentHandler", () => {
        it("should return 401 if user is not authenticated", async () => {
            const req: any = { user: null, body: {} };
            const res = mockRes();

            await deleteCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if comment_id is missing", async () => {
            const req: any = { user: { id: "1" }, body: {} };
            const res = mockRes();

            await deleteCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Comment ID required",
            });
        });

        it("should return 400 if comment does not exist or is invalid", async () => {
            (dbDeleteCommentById as jest.Mock).mockResolvedValue(0);

            const req: any = {
                user: { id: "1" },
                body: { comment_id: 10 },
            };
            const res = mockRes();

            await deleteCommentHandler(req, res);

            expect(dbDeleteCommentById).toHaveBeenCalledWith({
                comment_id: 10,
                user_id: 1,
            });

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Invalid comment (doesn't exist)",
            });
        });

        it("should delete comment successfully", async () => {
            (dbDeleteCommentById as jest.Mock).mockResolvedValue(1);

            const req: any = {
                user: { id: "1" },
                body: { comment_id: 10 },
            };
            const res = mockRes();

            await deleteCommentHandler(req, res);

            expect(dbDeleteCommentById).toHaveBeenCalledWith({
                comment_id: 10,
                user_id: 1,
            });

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: "Successfully deleted comment",
            });
        });

        it("should return 500 if database call throws an error", async () => {
            (dbDeleteCommentById as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1" },
                body: { comment_id: 10 },
            };
            const res = mockRes();

            await deleteCommentHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });
});})
