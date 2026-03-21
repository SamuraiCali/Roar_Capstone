export type DB_USER = {
  id: number;
  email: string;
  username: string;
  password: string;
  created_at: Date;
};

export type DB_VIDEO = {
  id: number;
  user_id: number;
  key: string;
  title: string | null;
  description: string | null;
  duration_seconds: number | null;
  width: number | null;
  height: number | null;
  created_at: Date;
};

export type DB_COMMENT = {
  id: number;
  user_id: number;
  video_id: number;
  content: string;
  parent_comment_id: number | null;
  created_at: Date;
};

export type DB_COMMENT_WITH_REPLY_COUNT = DB_COMMENT & { reply_count: number };
