--
-- PostgreSQL database dump
--

\restrict HKzfPEKGhaBdEcK7XLttiewWDlC6Hi528jPvCtQpkOtqdraFRtC8U25DP6mEVis

-- Dumped from database version 15.17 (Debian 15.17-1.pgdg13+1)
-- Dumped by pg_dump version 15.17 (Debian 15.17-1.pgdg13+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: comment_likes; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.comment_likes (
    user_id integer NOT NULL,
    comment_id integer NOT NULL,
    created_at timestamp without time zone DEFAULT now()
);


ALTER TABLE public.comment_likes OWNER TO myuser;

--
-- Name: comments; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.comments (
    id integer NOT NULL,
    user_id integer NOT NULL,
    video_id integer NOT NULL,
    content text NOT NULL,
    parent_comment_id integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.comments OWNER TO myuser;

--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.comments_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.comments_id_seq OWNER TO myuser;

--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: followers; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.followers (
    id integer NOT NULL,
    follower_id integer NOT NULL,
    following_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.followers OWNER TO myuser;

--
-- Name: followers_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.followers_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.followers_id_seq OWNER TO myuser;

--
-- Name: followers_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.followers_id_seq OWNED BY public.followers.id;


--
-- Name: likes; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.likes (
    id integer NOT NULL,
    user_id integer NOT NULL,
    video_id integer NOT NULL,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.likes OWNER TO myuser;

--
-- Name: likes_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.likes_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.likes_id_seq OWNER TO myuser;

--
-- Name: likes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.likes_id_seq OWNED BY public.likes.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE public.tags OWNER TO myuser;

--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.tags_id_seq OWNER TO myuser;

--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: user_tag_preferences; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.user_tag_preferences (
    user_id integer NOT NULL,
    tag_id integer NOT NULL,
    score integer DEFAULT 0
);


ALTER TABLE public.user_tag_preferences OWNER TO myuser;

--
-- Name: users; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.users (
    id integer NOT NULL,
    username character varying(50) NOT NULL,
    email character varying(100) NOT NULL,
    password character varying(255) NOT NULL,
    profile_image_key character varying(255),
    bio character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO myuser;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.users_id_seq OWNER TO myuser;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: video_tags; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.video_tags (
    video_id integer NOT NULL,
    tag_id integer NOT NULL
);


ALTER TABLE public.video_tags OWNER TO myuser;

--
-- Name: videos; Type: TABLE; Schema: public; Owner: myuser
--

CREATE TABLE public.videos (
    id integer NOT NULL,
    user_id integer NOT NULL,
    key text NOT NULL,
    title text,
    description text,
    duration_seconds integer,
    width integer,
    height integer,
    created_at timestamp with time zone DEFAULT now()
);


ALTER TABLE public.videos OWNER TO myuser;

--
-- Name: videos_id_seq; Type: SEQUENCE; Schema: public; Owner: myuser
--

CREATE SEQUENCE public.videos_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.videos_id_seq OWNER TO myuser;

--
-- Name: videos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: myuser
--

ALTER SEQUENCE public.videos_id_seq OWNED BY public.videos.id;


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: followers id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.followers ALTER COLUMN id SET DEFAULT nextval('public.followers_id_seq'::regclass);


--
-- Name: likes id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.likes ALTER COLUMN id SET DEFAULT nextval('public.likes_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: videos id; Type: DEFAULT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.videos ALTER COLUMN id SET DEFAULT nextval('public.videos_id_seq'::regclass);


--
-- Data for Name: comment_likes; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.comment_likes (user_id, comment_id, created_at) FROM stdin;
1	1	2026-04-17 05:32:24.013863
1	2	2026-04-17 05:32:29.554004
1	4	2026-04-17 05:39:15.154527
9	5	2026-04-17 05:41:30.79105
9	6	2026-04-17 05:43:40.066193
9	4	2026-04-17 05:45:29.673554
9	7	2026-04-17 05:45:31.277142
9	8	2026-04-17 05:45:33.145681
9	1	2026-04-17 05:45:39.214474
9	2	2026-04-17 05:45:40.672627
9	3	2026-04-17 05:45:42.44399
9	9	2026-04-17 05:46:00.725444
9	10	2026-04-17 05:46:25.779941
10	9	2026-04-17 05:52:05.650245
10	1	2026-04-17 05:52:06.304855
10	12	2026-04-17 05:52:17.132845
10	13	2026-04-17 05:53:01.477195
10	10	2026-04-17 05:53:02.314091
10	7	2026-04-17 05:53:02.974294
10	4	2026-04-17 05:53:03.690855
10	8	2026-04-17 05:53:16.596012
10	14	2026-04-17 05:53:17.522766
10	15	2026-04-17 05:53:42.85572
10	5	2026-04-17 05:53:54.877542
10	16	2026-04-17 05:54:11.820281
10	11	2026-04-17 05:54:28.620563
10	17	2026-04-17 05:55:13.11955
10	6	2026-04-17 05:55:23.952892
10	18	2026-04-17 05:55:39.71444
10	19	2026-04-17 05:56:03.171886
11	20	2026-04-17 06:00:34.145171
11	21	2026-04-17 06:01:20.803839
11	19	2026-04-17 06:01:21.700997
11	13	2026-04-17 06:01:36.332471
11	10	2026-04-17 06:01:37.406716
11	7	2026-04-17 06:01:38.377218
11	4	2026-04-17 06:01:39.710165
11	8	2026-04-17 06:03:32.499541
11	14	2026-04-17 06:03:33.978199
11	22	2026-04-17 06:03:35.140847
11	12	2026-04-17 06:04:12.196823
11	9	2026-04-17 06:04:13.004312
11	1	2026-04-17 06:04:13.827122
11	23	2026-04-17 06:04:52.622683
11	16	2026-04-17 06:05:27.967652
11	5	2026-04-17 06:05:29.072017
11	24	2026-04-17 06:06:02.068501
11	6	2026-04-17 06:07:01.623502
11	18	2026-04-17 06:07:02.399988
11	25	2026-04-17 06:07:17.40574
11	26	2026-04-17 06:09:58.70291
12	27	2026-04-17 06:17:37.354229
12	28	2026-04-17 06:18:18.035488
12	30	2026-04-17 06:19:19.911217
12	29	2026-04-17 06:19:20.660174
12	21	2026-04-17 06:19:21.434866
12	19	2026-04-17 06:19:22.31737
12	31	2026-04-17 06:19:49.022768
12	13	2026-04-17 06:20:18.267726
12	10	2026-04-17 06:20:18.851207
12	7	2026-04-17 06:20:19.577933
12	4	2026-04-17 06:20:20.237735
12	23	2026-04-17 06:20:42.642725
12	12	2026-04-17 06:20:43.467209
12	9	2026-04-17 06:20:44.137767
12	1	2026-04-17 06:20:44.922793
12	2	2026-04-17 06:20:50.393686
12	25	2026-04-17 06:21:05.571668
12	18	2026-04-17 06:21:06.082849
12	6	2026-04-17 06:21:06.765731
12	16	2026-04-17 06:21:19.547912
12	24	2026-04-17 06:21:20.074155
12	5	2026-04-17 06:21:20.950436
12	32	2026-04-17 06:21:57.825712
12	33	2026-04-17 06:21:58.49436
12	20	2026-04-17 06:22:07.486425
12	34	2026-04-17 06:22:23.142064
\.


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.comments (id, user_id, video_id, content, parent_comment_id, created_at) FROM stdin;
1	1	1	You were flying high like larry #overthinkinghooper	\N	2026-04-17 05:30:06.130169+00
2	2	1	Genuinely, larry would be impressed	1	2026-04-17 05:30:06.130169+00
3	3	1	Who is larry	1	2026-04-17 05:30:06.130169+00
4	1	3	GO PANTHERS	\N	2026-04-17 05:39:12.444772+00
5	9	4	Great edit lol	\N	2026-04-17 05:41:28.815327+00
6	9	5	Corey Stevenson man, what a shot	\N	2026-04-17 05:43:38.261535+00
7	9	3	This audio is so hype	\N	2026-04-17 05:44:17.20024+00
8	9	3	GO PANTHERS!!	4	2026-04-17 05:44:26.183961+00
9	9	1	Wow you were soaring like an eagle	\N	2026-04-17 05:45:58.372114+00
10	9	3	What’s the audio called	\N	2026-04-17 05:46:23.867605+00
11	9	6	Follow my page for more more Miami sports Roars!	\N	2026-04-17 05:48:08.202803+00
12	10	1	OMG	\N	2026-04-17 05:52:15.068052+00
13	10	3	Show them what we’re made of!	\N	2026-04-17 05:52:59.766452+00
14	10	3	GO PANTHERS!!!	4	2026-04-17 05:53:14.40406+00
15	10	3	Not sure, but I think that’s Bill Murray doing the voiceover	10	2026-04-17 05:53:35.977156+00
16	10	4	hahaha whose idea was this	\N	2026-04-17 05:54:10.46629+00
17	10	6	I think I will, you have eyes on every game across FIU somehow	11	2026-04-17 05:55:05.230714+00
18	10	5	Nothing but net	\N	2026-04-17 05:55:38.326435+00
19	10	2	Wow this looks fun, can I try playing with you guys later?	\N	2026-04-17 05:56:01.765589+00
20	11	7	Good luck this semester, the football team this year is the best we’ve ever had	\N	2026-04-17 06:00:32.269056+00
21	11	2	Good rally guys	\N	2026-04-17 06:01:18.881789+00
22	11	3	GO PANTHERS !!!!!	4	2026-04-17 06:03:30.955668+00
23	11	1	You need to join the FIU basketball team immediately 	\N	2026-04-17 06:04:50.247822+00
24	11	4	Y’all are getting too creative with these edits	\N	2026-04-17 06:06:00.094836+00
25	11	5	Clean	\N	2026-04-17 06:07:16.133906+00
26	11	9	I’m telling y’all, our football team this year is full of talent	\N	2026-04-17 06:09:56.430908+00
27	12	10	I’m always at the courts after class on Friday, come by if you want to run a match	\N	2026-04-17 06:17:35.116263+00
28	12	11	I was in flow state here	\N	2026-04-17 06:18:16.300196+00
29	12	2	Cleannn	\N	2026-04-17 06:18:43.731569+00
30	12	2	That block was unbelievable, lets run a match at Parkview gym one of these days	\N	2026-04-17 06:19:18.252825+00
31	12	2	Of course, everyone’s welcome :)	19	2026-04-17 06:19:43.208708+00
32	12	4	LOL	\N	2026-04-17 06:21:24.039417+00
33	12	4	Nah you guys are crazy	\N	2026-04-17 06:21:56.240954+00
34	12	7	Is that Crandon Park on Key Biscayne? I love that place	\N	2026-04-17 06:22:21.533037+00
\.


--
-- Data for Name: followers; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.followers (id, follower_id, following_id, created_at) FROM stdin;
1	1	2	2026-04-17 05:30:06.146181+00
2	1	3	2026-04-17 05:30:06.146181+00
3	2	1	2026-04-17 05:30:06.146181+00
4	2	3	2026-04-17 05:30:06.146181+00
5	2	4	2026-04-17 05:30:06.146181+00
6	2	5	2026-04-17 05:30:06.146181+00
7	3	1	2026-04-17 05:30:06.146181+00
8	4	2	2026-04-17 05:30:06.146181+00
9	5	2	2026-04-17 05:30:06.146181+00
10	6	2	2026-04-17 05:30:06.146181+00
11	9	2	2026-04-17 05:48:58.325987+00
12	9	1	2026-04-17 05:49:05.622128+00
13	12	9	2026-04-17 06:20:26.817429+00
14	12	2	2026-04-17 06:20:31.535891+00
15	12	10	2026-04-17 06:22:03.524287+00
\.


--
-- Data for Name: likes; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.likes (id, user_id, video_id, created_at) FROM stdin;
1	1	1	2026-04-17 05:30:06.119355+00
2	2	1	2026-04-17 05:30:06.119355+00
3	3	1	2026-04-17 05:30:06.119355+00
4	1	4	2026-04-17 05:38:37.618081+00
5	1	3	2026-04-17 05:38:52.309136+00
6	9	1	2026-04-17 05:41:13.6758+00
7	9	4	2026-04-17 05:41:16.602173+00
8	9	5	2026-04-17 05:43:22.968199+00
10	9	2	2026-04-17 05:43:56.539301+00
11	9	3	2026-04-17 05:44:08.764007+00
12	9	6	2026-04-17 05:47:40.894477+00
13	10	3	2026-04-17 05:50:49.444998+00
14	10	7	2026-04-17 05:51:54.276163+00
15	10	1	2026-04-17 05:52:02.749289+00
16	10	4	2026-04-17 05:53:52.156756+00
17	10	6	2026-04-17 05:54:16.044374+00
18	10	5	2026-04-17 05:55:21.772676+00
19	10	2	2026-04-17 05:55:44.09116+00
20	11	8	2026-04-17 05:59:20.985286+00
21	11	7	2026-04-17 05:59:39.557731+00
22	11	2	2026-04-17 06:01:03.137937+00
23	11	3	2026-04-17 06:01:34.334144+00
24	11	1	2026-04-17 06:04:09.4343+00
25	11	4	2026-04-17 06:05:42.032069+00
26	11	5	2026-04-17 06:06:59.41202+00
27	11	6	2026-04-17 06:07:08.539937+00
28	11	9	2026-04-17 06:09:32.085914+00
29	12	10	2026-04-17 06:16:51.174609+00
31	12	11	2026-04-17 06:18:00.667624+00
32	12	2	2026-04-17 06:18:34.681323+00
33	12	1	2026-04-17 06:20:38.802056+00
34	12	4	2026-04-17 06:21:17.673499+00
35	12	7	2026-04-17 06:22:05.274214+00
36	12	3	2026-04-17 06:22:28.489291+00
\.


--
-- Data for Name: tags; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.tags (id, name) FROM stdin;
1	basketball
2	volleyball
3	baseball
4	soccer
5	football
6	other
\.


--
-- Data for Name: user_tag_preferences; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.user_tag_preferences (user_id, tag_id, score) FROM stdin;
1	1	10
9	1	3
9	5	3
10	5	3
11	5	3
12	2	3
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.users (id, username, email, password, profile_image_key, bio, created_at) FROM stdin;
2	jordan	jordan@fiu.edu	hashedpassword1	\N	\N	2026-04-17 05:30:06.102748
3	lebon	lebon@fiu.edu	hashedpassword2	\N	\N	2026-04-17 05:30:06.102748
4	houston	houston@fiu.edu	hashedpassword2	\N	\N	2026-04-17 05:30:06.102748
5	jimmy	jimmy@fiu.edu	hashedpassword2	\N	\N	2026-04-17 05:30:06.102748
6	rust	rust@fiu.edu	hashedpassword2	\N	\N	2026-04-17 05:30:06.102748
7	sydney	sydney@fiu.edu	hashedpassword2	\N	\N	2026-04-17 05:30:06.102748
8	hoxton	hoxton@fiu.edu	hashedpassword2	\N	\N	2026-04-17 05:30:06.102748
1	basketballenjoyer	basketball@fiu.edu	bbb83ee7162556ae010069ad0143560c:e9ad462accac9c16a1e906f30c19e6ab5f1ca0ebf2d017fbf6887e3c3a14d1af15e50067eaa17ac6970e32cf875e48513fa02004a6d0532a76cd309ca4714a30	profile-images/1/avatar.jpg	FIU 2026 // Always at Parkview Basketball Court	2026-04-17 05:30:06.102748
9	MiamiSports	miamisports@fiu.edu	d32b2a5a63e8a74e86f6763a9d15f958:ba19a0020c0607e645de2fe35bf4e8c5a52113d9f26b2ca4849ab4af72b0dee11f8087d26b4fad95c6995ec7ef996bc218558f0627f15d719ea11fda95395209	profile-images/9/avatar.jpg	Keeping you updated on all Miami sports	2026-04-17 05:40:49.378007
10	karlaaa	karla@fiu.edu	6aa353616ac18586af5bff4450443024:a122f4a1f33367c1b5289b230ed179a4c8d9ad23e181f06a733f699922583df0bc5342d71a0a0f1aa9d0cc70ff4ce20085069215c54dd4a78f0146a8545a5158	profile-images/10/avatar.jpg	Football <3 FIU 2026	2026-04-17 05:50:47.535709
11	NewEraFootball	newera@fiu.edu	79a554aa4660a324e43c3cca9e7670ef:b21e7b998167f67fdf4f6a44661d4e4ee98e7b942f5ccbfa8f56da269c917b79a189aa7fe21de6ff0cd379f713f9088ebb57d1d3ceaf2b1689b7184fbdaa1cb9	profile-images/11/avatar.jpg	Training the new era of football	2026-04-17 05:58:35.601174
12	KarsVolleyball	karsvolleyball@fiu.edu	5e17b6e1e12a9ba1fdbcb42fdea2fa9c:a12ed769d0f8e6611cf90f0c0f18c092191bd034a660ea09fc7bc6ce5da2843c88072b79d42ce3cfb57fef130083472b2ce4e5d8c0aaa46e070eddef50c90385	profile-images/12/avatar.jpg	Always down for a volleyball game	2026-04-17 06:14:36.442961
\.


--
-- Data for Name: video_tags; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.video_tags (video_id, tag_id) FROM stdin;
1	1
2	1
3	2
4	1
5	1
6	1
7	5
8	5
9	5
10	2
11	2
\.


--
-- Data for Name: videos; Type: TABLE DATA; Schema: public; Owner: myuser
--

COPY public.videos (id, user_id, key, title, description, duration_seconds, width, height, created_at) FROM stdin;
1	2	videos/1774159425783-basketball_dunk.mp4	#basketball #dunk #swoosh	Anybody can get it 🤦🏾‍♂️ W camera woman	\N	\N	\N	2026-04-17 05:30:06.110817+00
2	2	videos/1774159834890-volleyball_rally.mp4	#volleyball #gym	POV: you’re right in the middle of the rally at FIU 🏐	\N	\N	\N	2026-04-17 05:30:06.110817+00
3	2	videos/1776123407880-football-game.mp4	#football #pantherpride #win	It’s game day guys. Won 42-9, everyone was in flow state #fiufootball #collegelife #fiu #fyp #football	\N	\N	\N	2026-04-17 05:30:06.110817+00
4	1	videos/1776404301893-D8E64349-02B8-4824-9344-029D30CF07B7.mov	#basketball	Just having fun mannnnn👾 FIU Intramural Basketball Bag Work	\N	\N	\N	2026-04-17 05:38:22.770434+00
5	9	videos/1776404596344-3F66D3D0-CF6D-4712-B7AF-1523EAE6FE5C.mov	#basketball	@STBCOREY HITS FROM THE COASTLINE AND FIU (@FIUHoops) WINS	\N	\N	\N	2026-04-17 05:43:16.948704+00
6	9	videos/1776404855220-5C960EFA-88DC-4417-8D6B-9876975164DD.mov	#basketball	FIU boys basketball Miami vic game	\N	\N	\N	2026-04-17 05:47:35.872332+00
7	10	videos/1776405108727-A874AD9F-4F90-4915-AC3C-DBB810193FC5.mov	#football	What better way to start the summer than with your toes in the sand! 	\N	\N	\N	2026-04-17 05:51:49.397787+00
8	11	videos/1776405554791-767E3C39-A0D6-4BAE-8F39-1C68BA5A3C3A.mov	#football	Big showing from FIU’s senior leader	\N	\N	\N	2026-04-17 05:59:15.532384+00
9	11	videos/1776406164488-B57BC3F9-AFA5-4932-A0CE-C710A4A76A96.mov	#football	FIU's football team is taking on the 2026 season with their new quarterback J.J. Kohl.	\N	\N	\N	2026-04-17 06:09:25.321645+00
10	12	videos/1776406568951-DEE8D222-A1EA-4A1D-94AE-B9FBA0E4DA47.mov	#volleyball	6v6 indoor volleyball runs at FIU just hit different 🏐 Every rally turns into a battle.	\N	\N	\N	2026-04-17 06:16:10.226738+00
11	12	videos/1776406603741-3442D5AB-D8F5-48B7-BED4-70A7BA774145.mov	#volleyball	Open gym warriors 🌚	\N	\N	\N	2026-04-17 06:16:44.387013+00
\.


--
-- Name: comments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.comments_id_seq', 34, true);


--
-- Name: followers_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.followers_id_seq', 15, true);


--
-- Name: likes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.likes_id_seq', 36, true);


--
-- Name: tags_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.tags_id_seq', 6, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.users_id_seq', 12, true);


--
-- Name: videos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: myuser
--

SELECT pg_catalog.setval('public.videos_id_seq', 11, true);


--
-- Name: comment_likes comment_likes_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comment_likes
    ADD CONSTRAINT comment_likes_pkey PRIMARY KEY (user_id, comment_id);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: followers followers_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT followers_pkey PRIMARY KEY (id);


--
-- Name: likes likes_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT likes_pkey PRIMARY KEY (id);


--
-- Name: tags tags_name_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_name_key UNIQUE (name);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: followers unique_follow; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT unique_follow UNIQUE (follower_id, following_id);


--
-- Name: likes unique_like; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT unique_like UNIQUE (user_id, video_id);


--
-- Name: user_tag_preferences user_tag_preferences_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.user_tag_preferences
    ADD CONSTRAINT user_tag_preferences_pkey PRIMARY KEY (user_id, tag_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: video_tags video_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.video_tags
    ADD CONSTRAINT video_tags_pkey PRIMARY KEY (video_id, tag_id);


--
-- Name: videos videos_key_key; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT videos_key_key UNIQUE (key);


--
-- Name: videos videos_pkey; Type: CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT videos_pkey PRIMARY KEY (id);


--
-- Name: idx_comment_likes_comment_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_comment_likes_comment_id ON public.comment_likes USING btree (comment_id);


--
-- Name: idx_comments_parent_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_comments_parent_id ON public.comments USING btree (parent_comment_id);


--
-- Name: idx_comments_video_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_comments_video_id ON public.comments USING btree (video_id);


--
-- Name: idx_follower_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_follower_id ON public.followers USING btree (follower_id);


--
-- Name: idx_following_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_following_id ON public.followers USING btree (following_id);


--
-- Name: idx_likes_user_video; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_likes_user_video ON public.likes USING btree (user_id, video_id);


--
-- Name: idx_likes_video_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_likes_video_id ON public.likes USING btree (video_id);


--
-- Name: idx_user_tag_prefs_tag_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_user_tag_prefs_tag_id ON public.user_tag_preferences USING btree (tag_id);


--
-- Name: idx_user_tag_prefs_user_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_user_tag_prefs_user_id ON public.user_tag_preferences USING btree (user_id);


--
-- Name: idx_video_tags_tag_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_video_tags_tag_id ON public.video_tags USING btree (tag_id);


--
-- Name: idx_video_tags_video_id; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_video_tags_video_id ON public.video_tags USING btree (video_id);


--
-- Name: idx_videos_created_at; Type: INDEX; Schema: public; Owner: myuser
--

CREATE INDEX idx_videos_created_at ON public.videos USING btree (created_at DESC);


--
-- Name: comment_likes comment_likes_comment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comment_likes
    ADD CONSTRAINT comment_likes_comment_id_fkey FOREIGN KEY (comment_id) REFERENCES public.comments(id) ON DELETE CASCADE;


--
-- Name: comment_likes comment_likes_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comment_likes
    ADD CONSTRAINT comment_likes_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: comments fk_comment_comment; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comment_comment FOREIGN KEY (parent_comment_id) REFERENCES public.comments(id) ON DELETE CASCADE;


--
-- Name: comments fk_comment_user; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comment_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: comments fk_comment_video; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_comment_video FOREIGN KEY (video_id) REFERENCES public.videos(id) ON DELETE CASCADE;


--
-- Name: followers fk_follower; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT fk_follower FOREIGN KEY (follower_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: followers fk_following; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.followers
    ADD CONSTRAINT fk_following FOREIGN KEY (following_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: likes fk_like_user; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT fk_like_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: likes fk_like_video; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.likes
    ADD CONSTRAINT fk_like_video FOREIGN KEY (video_id) REFERENCES public.videos(id) ON DELETE CASCADE;


--
-- Name: videos fk_user; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.videos
    ADD CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: user_tag_preferences user_tag_preferences_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.user_tag_preferences
    ADD CONSTRAINT user_tag_preferences_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: user_tag_preferences user_tag_preferences_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.user_tag_preferences
    ADD CONSTRAINT user_tag_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: video_tags video_tags_tag_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.video_tags
    ADD CONSTRAINT video_tags_tag_id_fkey FOREIGN KEY (tag_id) REFERENCES public.tags(id) ON DELETE CASCADE;


--
-- Name: video_tags video_tags_video_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: myuser
--

ALTER TABLE ONLY public.video_tags
    ADD CONSTRAINT video_tags_video_id_fkey FOREIGN KEY (video_id) REFERENCES public.videos(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict HKzfPEKGhaBdEcK7XLttiewWDlC6Hi528jPvCtQpkOtqdraFRtC8U25DP6mEVis

