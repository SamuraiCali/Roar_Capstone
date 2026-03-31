import {
    getFollowersHandler,
    getFollowersCountHandler,
    followUserHandler,
    unfollowHandler,
} from "../controllers/followerController";
import {
    dbGetFollowersFromUsername,
    dbGetFollowersCountFromUsername,
    dbDeleteFollow,
    dbCreateFollow,
    dbGetUserByUsername,
} from "../utils/dbUtils";

jest.mock("../utils/dbUtils");

describe("followerController", () => {
    const mockRes = () => {
        const res: any = {};
        res.status = jest.fn().mockReturnValue(res);
        res.json = jest.fn().mockReturnValue(res);
        return res;
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    //================================================
    //getFollowersHandler Tests
    //================================================
    describe("getFollowersHandler", () => {
        it("should return 400 if username is missing", async () => {
            const req: any = { params: {} };
            const res = mockRes();

            await getFollowersHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Username required",
            });
        });

        it("should return followers successfully", async () => {
            const fakeFollowers = [
                { id: 1, username: "user1" },
                { id: 2, username: "user2" },
            ];

            (dbGetFollowersFromUsername as jest.Mock).mockResolvedValue(
                fakeFollowers,
            );

            const req: any = { params: { username: "testuser" } };
            const res = mockRes();

            await getFollowersHandler(req, res);

            expect(dbGetFollowersFromUsername).toHaveBeenCalledWith("testuser");
            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                followers: fakeFollowers,
            });
        });

        it("should return empty array if user has no followers", async () => {
            (dbGetFollowersFromUsername as jest.Mock).mockResolvedValue([]);

            const req: any = { params: { username: "testuser" } };
            const res = mockRes();

            await getFollowersHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                followers: [],
            });
        });

        it("should return 500 if database call fails", async () => {
            (dbGetFollowersFromUsername as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = { params: { username: "testuser" } };
            const res = mockRes();

            await getFollowersHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });

    //================================================
    //followUserHandler Tests
    //================================================
    describe("followUserHandler", () => {
        it("should return 400 if user is not authenticated", async () => {
            const req: any = { user: null, params: { username: "test" } };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if username param is missing", async () => {
            const req: any = { user: { id: "1", username: "me" }, params: {} };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Username required",
            });
        });

        it("should return 400 if user tries to follow themselves", async () => {
            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "me" },
            };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot follow self",
            });
        });

        it("should successfully follow a user", async () => {
            const fakeFollow = { follower_id: 1, following_username: "other" };

            (dbCreateFollow as jest.Mock).mockResolvedValue({
                rowCount: 1,
                rows: [fakeFollow],
            });

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(dbCreateFollow).toHaveBeenCalledWith({
                follower_id: 1,
                following_username: "other",
            });

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({ follow: fakeFollow });
        });

        it("should return 404 if user to follow does not exist", async () => {
            (dbCreateFollow as jest.Mock).mockResolvedValue({
                rowCount: 0,
                rows: [],
            });

            (dbGetUserByUsername as jest.Mock).mockResolvedValue({
                rowCount: 0,
            });

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "ghost" },
            };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(dbGetUserByUsername).toHaveBeenCalledWith("ghost");
            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({ error: "User not found" });
        });

        it("should return 400 if already following user", async () => {
            (dbCreateFollow as jest.Mock).mockResolvedValue({
                rowCount: 0,
                rows: [],
            });

            (dbGetUserByUsername as jest.Mock).mockResolvedValue({
                rowCount: 1,
            });

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Already following this user",
            });
        });

        it("should return 400 if unique constraint error occurs", async () => {
            (dbCreateFollow as jest.Mock).mockRejectedValue({
                code: "23505",
            });

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "You already follow this user",
            });
        });

        it("should return 500 for unexpected errors", async () => {
            (dbCreateFollow as jest.Mock).mockRejectedValue(
                new Error("Unknown error"),
            );

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await followUserHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });

    //======================================================
    //unfollowHandler Tests
    //======================================================
    describe("unfollowHandler", () => {
        it("should return 400 if user is not authenticated", async () => {
            const req: any = { user: null, params: { username: "other" } };
            const res = mockRes();

            await unfollowHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({ error: "Unauthorized" });
        });

        it("should return 400 if username param is missing", async () => {
            const req: any = { user: { id: "1", username: "me" }, params: {} };
            const res = mockRes();

            await unfollowHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Username required",
            });
        });

        it("should return 400 if user tries to unfollow themselves", async () => {
            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "me" },
            };
            const res = mockRes();

            await unfollowHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Cannot unfollow self",
            });
        });

        it("should return 404 if follow relationship does not exist", async () => {
            (dbDeleteFollow as jest.Mock).mockResolvedValue(0);

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await unfollowHandler(req, res);

            expect(dbDeleteFollow).toHaveBeenCalledWith({
                follower_id: 1,
                following_username: "other",
            });

            expect(res.status).toHaveBeenCalledWith(404);
            expect(res.json).toHaveBeenCalledWith({
                error: "Follow relationship not found",
            });
        });

        it("should successfully unfollow a user", async () => {
            (dbDeleteFollow as jest.Mock).mockResolvedValue(1);

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await unfollowHandler(req, res);

            expect(dbDeleteFollow).toHaveBeenCalledWith({
                follower_id: 1,
                following_username: "other",
            });

            expect(res.status).toHaveBeenCalledWith(200);
            expect(res.json).toHaveBeenCalledWith({
                message: "Successfully unfollowed user other",
            });
        });

        it("should return 500 if dbDeleteFollow throws an error", async () => {
            (dbDeleteFollow as jest.Mock).mockRejectedValue(
                new Error("DB error"),
            );

            const req: any = {
                user: { id: "1", username: "me" },
                params: { username: "other" },
            };
            const res = mockRes();

            await unfollowHandler(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error",
            });
        });
    });
});
