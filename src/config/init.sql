CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO users (username, email, password)
VALUES
('jordan', 'jordan@fiu.edu', 'hashedpassword1'),
('chains', 'chains@fiu.edu', 'hashedpassword3'),
('lebon', 'lebon@fiu.edu', 'hashedpassword2'),
('sokol', 'sokol@fiu.edu', 'hashedpassword2'),
('houston', 'houston@fiu.edu', 'hashedpassword2'),
('wolf', 'wolf@fiu.edu', 'hashedpassword2'),
('jimmy', 'jimmy@fiu.edu', 'hashedpassword2'),
('rust', 'rust@fiu.edu', 'hashedpassword2'),
('sydney', 'sydney@fiu.edu', 'hashedpassword2'),
('hoxton', 'hoxton@fiu.edu', 'hashedpassword2');


CREATE TABLE videos (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    key TEXT NOT NULL UNIQUE,
    title TEXT,
    description TEXT,
    duration_seconds INT,
    width INT,
    height INT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT fk_user
        FOREIGN KEY(user_id)
        REFERENCES users(id)
        ON DELETE CASCADE
);

INSERT INTO videos (user_id, key, title, description) VALUES 
(1, 'videos/1774055669348-file_example_MP4_480_1_5MG.mp4', 'My Example Video', 'Mediatok Larp Tutorial');

CREATE INDEX idx_videos_created_at
ON videos(created_at DESC);

CREATE TABLE IF NOT EXISTS likes (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    video_id INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_like_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_like_video FOREIGN KEY(video_id) REFERENCES videos(id) ON DELETE CASCADE,
    CONSTRAINT unique_like UNIQUE(user_id, video_id)
);

INSERT INTO likes (user_id, video_id) 
VALUES 
(1, 1),
(2, 1),
(3, 1);

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL,
    video_id INT NOT NULL,
    content TEXT NOT NULL,
    parent_comment_id INTEGER NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_comment_user FOREIGN KEY(user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_video FOREIGN KEY(video_id) REFERENCES videos(id) ON DELETE CASCADE,
    CONSTRAINT fk_comment_comment FOREIGN KEY (parent_comment_id) REFERENCES comments(id) ON DELETE CASCADE
);

INSERT INTO comments (user_id, video_id, content, parent_comment_id)
VALUES
(1, 1, 'Larp larp larp', NULL),
(2, 1, 'shut up dimwit', 1),
(3, 1, 'No, no he has a point', 1);

CREATE INDEX IF NOT EXISTS idx_comments_video_id ON comments(video_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id);

CREATE TABLE IF NOT EXISTS followers (
    id SERIAL PRIMARY KEY,
    follower_id INT NOT NULL,  
    following_id INT NOT NULL, 
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT fk_follower FOREIGN KEY(follower_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_following FOREIGN KEY(following_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT unique_follow UNIQUE(follower_id, following_id)
);

INSERT INTO followers (follower_id, following_id)
VALUES
(1, 2), 
(1, 3),  
(2, 1),  
(3, 1);  

CREATE INDEX IF NOT EXISTS idx_following_id ON followers(following_id);
CREATE INDEX IF NOT EXISTS idx_follower_id ON followers(follower_id);

CREATE INDEX IF NOT EXISTS idx_likes_video_id ON likes(video_id);
CREATE INDEX IF NOT EXISTS idx_likes_user_video ON likes(user_id, video_id);