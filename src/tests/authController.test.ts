import { hashPassword, verifyPassword } from "../utils/passwordUtils";
import { register, login } from "../controllers/authController";
import { dbCreateUser, dbGetUserByEmail } from "../utils/dbUtils";
import jwt from "jsonwebtoken";

jest.mock("../utils/dbUtils");
jest.mock("../utils/passwordUtils");
jest.mock("jsonwebtoken");

describe("authController", () => {
    const mockRes = () => {
        const res: any = {};
        res.status = jest.fn().mockReturnValue(res);
        res.json = jest.fn().mockReturnValue(res);
        res.cookie = jest.fn().mockReturnValue(res);
        return res;
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    //=============================================
    //Register Tests
    //=============================================
    describe("register", () => {
        it("should return 400 if required fields are missing", async () => {
            const req: any = { body: {} };
            const res = mockRes();

            await register(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "All fields are required",
            });
        });

        it("should return 400 if user already exists", async () => {
            (dbGetUserByEmail as jest.Mock).mockResolvedValue({ id: 1 });

            const req: any = {
                body: {
                    username: "test",
                    email: "test@test.com",
                    password: "123",
                },
            };
            const res = mockRes();

            await register(req, res);

            expect(dbGetUserByEmail).toHaveBeenCalledWith("test@test.com");
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "User already exists",
            });
        });

        it("should return 500 if dbCreateUser fails", async () => {
            (dbGetUserByEmail as jest.Mock).mockResolvedValue(null);
            (hashPassword as jest.Mock).mockResolvedValue("hashed");
            (dbCreateUser as jest.Mock).mockResolvedValue(null);

            const req: any = {
                body: {
                    username: "test",
                    email: "test@test.com",
                    password: "123",
                },
            };
            const res = mockRes();

            await register(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Internal Server Error: Failed to create user",
            });
        });

        it("should successfully register a user", async () => {
            const fakeUser = {
                id: 1,
                username: "test",
                email: "test@test.com",
            };

            (dbGetUserByEmail as jest.Mock).mockResolvedValue(null);
            (hashPassword as jest.Mock).mockResolvedValue("hashedPassword");
            (dbCreateUser as jest.Mock).mockResolvedValue(fakeUser);
            (jwt.sign as jest.Mock).mockReturnValue("fake-jwt-token");

            const req: any = {
                body: {
                    username: "test",
                    email: "test@test.com",
                    password: "123",
                },
            };
            const res = mockRes();

            await register(req, res);

            expect(hashPassword).toHaveBeenCalledWith("123");

            expect(dbCreateUser).toHaveBeenCalledWith({
                username: "test",
                email: "test@test.com",
                password: "hashedPassword",
            });

            expect(jwt.sign).toHaveBeenCalledWith(
                { id: fakeUser.id, username: fakeUser.username },
                expect.any(String),
                { expiresIn: "7d" },
            );

            expect(res.cookie).toHaveBeenCalledWith(
                "token",
                "fake-jwt-token",
                expect.objectContaining({
                    httpOnly: true,
                }),
            );

            expect(res.status).toHaveBeenCalledWith(201);
            expect(res.json).toHaveBeenCalledWith({
                message: "User registered",
                user: fakeUser,
            });
        });

        it("should return 500 if an unexpected error occurs", async () => {
            (dbGetUserByEmail as jest.Mock).mockRejectedValue(
                new Error("DB crash"),
            );

            const req: any = {
                body: {
                    username: "test",
                    email: "test@test.com",
                    password: "123",
                },
            };
            const res = mockRes();

            await register(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Server error",
            });
        });
    });

    //=============================================
    //login Tests
    //=============================================
    describe("login", () => {
        it("should return 400 if email or password is missing", async () => {
            const req: any = { body: {} };
            const res = mockRes();

            await login(req, res);

            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Email and password are required",
            });
        });

        it("should return 400 if user does not exist", async () => {
            (dbGetUserByEmail as jest.Mock).mockResolvedValue(null);

            const req: any = {
                body: { email: "test@test.com", password: "123" },
            };
            const res = mockRes();

            await login(req, res);

            expect(dbGetUserByEmail).toHaveBeenCalledWith("test@test.com");
            expect(res.status).toHaveBeenCalledWith(400);
            expect(res.json).toHaveBeenCalledWith({
                error: "Invalid credentials",
            });
        });

        it("should return 401 if password does not match", async () => {
            (dbGetUserByEmail as jest.Mock).mockResolvedValue({
                id: 1,
                username: "test",
                password: "hashed",
            });

            (verifyPassword as jest.Mock).mockResolvedValue(false);

            const req: any = {
                body: { email: "test@test.com", password: "wrong" },
            };
            const res = mockRes();

            await login(req, res);

            expect(verifyPassword).toHaveBeenCalledWith("wrong", "hashed");
            expect(res.status).toHaveBeenCalledWith(401);
            expect(res.json).toHaveBeenCalledWith({
                error: "Invalid credentials",
            });
        });

        it("should successfully log in and set cookie", async () => {
            const fakeUser = {
                id: 1,
                username: "test",
                password: "hashed",
            };

            (dbGetUserByEmail as jest.Mock).mockResolvedValue(fakeUser);
            (verifyPassword as jest.Mock).mockResolvedValue(true);
            (jwt.sign as jest.Mock).mockReturnValue("fake-token");

            const req: any = {
                body: { email: "test@test.com", password: "correct" },
            };
            const res = mockRes();

            await login(req, res);

            expect(jwt.sign).toHaveBeenCalledWith(
                { id: fakeUser.id, username: fakeUser.username },
                expect.any(String),
                { expiresIn: "7d" },
            );

            expect(res.cookie).toHaveBeenCalledWith(
                "token",
                "fake-token",
                expect.objectContaining({
                    httpOnly: true,
                }),
            );

            expect(res.json).toHaveBeenCalledWith({
                message: "Login successful",
            });
        });

        it("should return 500 if an unexpected error occurs", async () => {
            (dbGetUserByEmail as jest.Mock).mockRejectedValue(
                new Error("DB crash"),
            );

            const req: any = {
                body: { email: "test@test.com", password: "123" },
            };
            const res = mockRes();

            await login(req, res);

            expect(res.status).toHaveBeenCalledWith(500);
            expect(res.json).toHaveBeenCalledWith({
                error: "Server error",
            });
        });
    });
});
