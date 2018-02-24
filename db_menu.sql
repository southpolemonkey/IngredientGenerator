--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.2
-- Dumped by pg_dump version 9.6.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: plpythonu; Type: PROCEDURAL LANGUAGE; Schema: -; Owner: rongchenxuan
--

CREATE OR REPLACE PROCEDURAL LANGUAGE plpythonu;


ALTER PROCEDURAL LANGUAGE plpythonu OWNER TO rongchenxuan;

SET search_path = public, pg_catalog;

--
-- Name: add_ingredient(text, integer, text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION add_ingredient(c_name text, kind integer, p_name text[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$

DECLARE
	old_pid integer;
    new_cid integer;
    new_pid integer;
    tmp_pid integer;
    count_index integer;
    
BEGIN
	-- RETURN query
	
    -- 加入菜名表
    --菜名不存在
    IF NOT EXISTS (SELECT 1 FROM t_c WHERE t_c.name = c_name) THEN  
        SELECT MAX(ID) + 1 AS old_cid FROM t_c WHERE catergory = kind into new_cid;
        INSERT INTO t_c(id, name, catergory) VALUES(new_cid, c_name, kind);
        RAISE NOTICE '菜名: % 添加成功', c_name;
        
        -- 加入配料表
    	SELECT MAX(ID) into old_pid FROM t_p;
        SELECT 1 INTO count_index;
    	FOR i IN 1 .. array_upper(p_name, 1)
    	LOOP
    		IF NOT EXISTS (SELECT 1 FROM t_p WHERE t_p.name = p_name[i]) THEN  --配料表中不存在，新建编号
    			SELECT old_pid + count_index INTO new_pid;
    			INSERT INTO t_p(id, name) VALUES(new_pid, p_name[i]);
        		INSERT INTO t_s(c_id, p_id) VALUES(new_cid, new_pid);
        		RAISE NOTICE '配料: % 添加成功', p_name[i];
                SELECT count_index + 1 into count_index;
        	ELSE  --配料表中存在，查找编号
        		RAISE NOTICE '配料: % 已存在', p_name[i];
        		SELECT t_p.id FROM t_p WHERE t_p.name = p_name[i] INTO tmp_pid;
        		INSERT INTO t_s(c_id, p_id) VALUES(new_cid, tmp_pid);
        	END IF;
    	END LOOP;
        RETURN TRUE;
    -- 菜名存在
    ELSE
        RAISE NOTICE '菜名:% 已存在', c_name;
        RETURN FALSE;
    END IF; 	    
END; 

$$;


ALTER FUNCTION public.add_ingredient(c_name text, kind integer, p_name text[]) OWNER TO postgres;

--
-- Name: get_ingredient(text[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_ingredient(c_name text[]) RETURNS TABLE(p_name text)
    LANGUAGE plpgsql
    AS $$BEGIN
 RETURN QUERY
 
 SELECT t_p.name 
 FROM t_p 
 WHERE t_p.id in
 (
     select t_s.p_id 
     from t_s left join t_c on t_s.c_id = t_c.id 
     where t_c.name = ANY(c_name)
 );
 
 RAISE NOTICE 'Query done!';
 
END;  
$$;


ALTER FUNCTION public.get_ingredient(c_name text[]) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: history; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE history (
    id integer NOT NULL,
    menu_date date NOT NULL,
    title text NOT NULL
);


ALTER TABLE history OWNER TO postgres;

--
-- Name: history_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE history_id_seq OWNER TO postgres;

--
-- Name: history_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE history_id_seq OWNED BY history.id;


--
-- Name: t_c; Type: TABLE; Schema: public; Owner: rongchenxuan
--

CREATE TABLE t_c (
    id integer NOT NULL,
    name text NOT NULL,
    catergory integer
);


ALTER TABLE t_c OWNER TO rongchenxuan;

--
-- Name: t_fenlei; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE t_fenlei (
    kind integer,
    alias text
);


ALTER TABLE t_fenlei OWNER TO postgres;

--
-- Name: t_p; Type: TABLE; Schema: public; Owner: rongchenxuan
--

CREATE TABLE t_p (
    id integer NOT NULL,
    name text NOT NULL
);


ALTER TABLE t_p OWNER TO rongchenxuan;

--
-- Name: t_s; Type: TABLE; Schema: public; Owner: rongchenxuan
--

CREATE TABLE t_s (
    id integer NOT NULL,
    c_id integer,
    p_id integer,
    remark text
);


ALTER TABLE t_s OWNER TO rongchenxuan;

--
-- Name: t_s_id_seq; Type: SEQUENCE; Schema: public; Owner: rongchenxuan
--

CREATE SEQUENCE t_s_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE t_s_id_seq OWNER TO rongchenxuan;

--
-- Name: t_s_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: rongchenxuan
--

ALTER SEQUENCE t_s_id_seq OWNED BY t_s.id;


--
-- Name: history id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY history ALTER COLUMN id SET DEFAULT nextval('history_id_seq'::regclass);


--
-- Name: t_s id; Type: DEFAULT; Schema: public; Owner: rongchenxuan
--

ALTER TABLE ONLY t_s ALTER COLUMN id SET DEFAULT nextval('t_s_id_seq'::regclass);


--
-- Data for Name: history; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY history (id, menu_date, title) FROM stdin;
1	2018-03-02	元宵节
4	2018-03-08	妇女节
5	2018-05-02	老妈生日
6	2018-07-04	戎晨轩生日
7	2018-10-01	国庆节聚餐
8	2018-09-18	勿忘国耻吃顿饭
9	2018-05-01	劳动节
10	2018-02-21	周末小聚
11	2018-12-24	圣诞节
29	2018-01-01	test
30	2018-01-01	test
31	2018-01-01	test
32	2018-01-01	test
33	2018-01-01	test
34	2018-01-01	元旦
\.


--
-- Name: history_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('history_id_seq', 34, true);


--
-- Data for Name: t_c; Type: TABLE DATA; Schema: public; Owner: rongchenxuan
--

COPY t_c (id, name, catergory) FROM stdin;
101	红烧肉	1
102	响油鳝丝	1
103	清蒸小黄鱼	1
104	清蒸桂鱼	1
301	酒酿圆子	3
201	油豆腐黄豆芽	2
202	茭白木耳	2
203	西芹炒腐竹	2
105	泡椒牛蛙	1
204	鱼香茄子	2
106	淮扬软兜	1
107	白斩鸡	1
108	烤三文鱼	1
109	河虾	1
110	清炒虾仁	1
111	虾仁跑蛋	1
112	油爆虾	1
113	葱爆蛏子	1
114	蒜香排骨	1
115	咸菜炒墨鱼	1
116	毛蟹年糕	1
205	咸蛋黄芦笋	2
306	蕃茄菌菇汤	3
207	蒜蓉空心菜	2
208	蒜蓉油麦菜	2
401	酸辣汤	4
402	鸡汤	4
403	鱼头豆腐汤	4
209	凉拌木耳	2
210	糟毛豆	2
211	四喜烤麸	2
302	八宝饭	3
303	银耳羹	3
304	水果羹	3
212	开洋冬瓜	2
213	酒香草头	2
117	糖醋小排	1
118	豆豉蒸排骨	1
119	葱烤大排	1
120	椒盐排条	1
121	清蒸白水鱼	1
206	清炒菠菜	2
305	菜泡饭	3
214	炒青菜	2
122	肉糜炖蛋	1
123	梭子蟹烧南瓜	1
404	冬瓜番茄汤	4
124	清蒸鸦片鱼头	1
125	红烧鮰鱼	1
126	鱼香茄子煲	1
127	肉糜粉丝煲	1
215	清炒山药	2
128	清炒鳝糊	1
129	红烧牛蛙	1
130	清蒸鸦片鱼	1
131	蒸蛋	1
132	蒜香小排	1
133	目鱼芹菜	1
134	目鱼雪菜	1
135	目鱼青椒	1
136	凉拌海蜇	1
137	河鲫鱼塞肉	1
138	爆猪肝	1
139	菠菜炒蛋	1
140	清蒸鲳鱼	1
141	茄汁鲳鱼	1
142	清炒花蛤	1
143	蚝油花蛤	1
144	麻辣豆腐	1
145	糟卤沼虾	1
146	干煎带鱼	1
147	芹菜肉丝	1
148	清蒸带鱼	1
149	红烧带鱼	1
150	酒糟蒸带鱼	1
151	淮扬鳝丝	1
152	红烧鲫格郎	1
153	京酱肉丝	1
154	炒豇豆丁	1
155	土豆色拉	1
216	酸辣大白菜	2
217	有机花菜	2
218	土豆丝	2
219	油闷笋	2
220	四喜考夫	2
221	香菇青菜	2
222	炒杏鲍菇	2
223	豆芽油豆腐	2
224	西芹百合	2
225	清炒豆苗	2
307	土豆鸡毛菜汤	3
308	紫菜汤	3
\.


--
-- Data for Name: t_fenlei; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY t_fenlei (kind, alias) FROM stdin;
1	荤菜
2	素菜
3	点心
4	汤类
\.


--
-- Data for Name: t_p; Type: TABLE DATA; Schema: public; Owner: rongchenxuan
--

COPY t_p (id, name) FROM stdin;
1	大排
2	五花肉
3	猪小排
4	蹄髈
5	童子鸡
6	老母鸡
7	老鸭子
8	花蛤
9	蛏子
10	螺丝
11	黄鳝
12	桂鱼
13	鲳鱼
14	小黄鱼
15	带鱼
16	葱
17	姜
19	黑胡椒\n
18	大蒜
20	开洋
21	冬瓜
22	草头
23	白酒
24	豆豉
25	猪大排
27	椒盐
28	白水鱼
29	泡椒
30	牛蛙
31	鳝丝
32	草母鸡
33	三文鱼
34	柠檬
35	河虾
36	海虾仁
37	鸡蛋
38	猪肋排
39	乌贼鱼
40	雪菜
41	大闸蟹
42	年糕
43	油豆腐
44	黄豆芽
45	茭白
46	黑木耳
47	西芹
48	水芹
49	腐竹
50	茄子
51	甜面酱
52	豆瓣酱
53	咸蛋
54	芦笋
55	菠菜
56	空心菜
57	油麦菜
58	糟卤
59	毛豆
60	烤麸
61	干香菇
62	金针菜
63	花生
64	酒酿
65	小圆子
66	糖桂花
67	八宝饭
68	银耳
69	红枣
70	桂圆
71	莲心
72	苹果
73	生梨
74	橘子
75	香蕉
76	绢豆腐
77	金针菜
78	鲜香菇
79	金针菇
80	肉丝
81	胡萝卜
82	胖头鱼
83	青菜
84	蘑菇
85	肉糜
86	咸蛋黄
87	梭子蟹
88	南瓜
89	番茄
90	鸦片鱼头
91	老干妈
92	鮰鱼
93	粉丝
94	山药
95	白胡椒
96	冬笋
97	青椒
98	鸦片鱼
99	虾皮
100	小排骨
101	蒜泥
102	目鱼
103	芹菜
104	白罗卜
105	黄瓜
106	海蜇
107	河鲫鱼
108	内末
109	猪肝
110	蕃茄酱
111	蚝油
112	豆腐
113	辣酱
114	沼虾
115	酒糟
116	鲫格郎
117	豇豆
118	肉末
119	土豆
120	火腿肉
121	蛋黄酱
122	大白菜
123	有机花菜
124	香菇
125	
126	竹笋
127	考夫
128	针金菜
129	杏鲍菇
130	豆芽
131	百合
132	豆苗
133	菌茹
134	蕃茄
135	鸡毛菜
136	紫菜
137	窄菜
\.


--
-- Data for Name: t_s; Type: TABLE DATA; Schema: public; Owner: rongchenxuan
--

COPY t_s (id, c_id, p_id, remark) FROM stdin;
6	101	2	\N
9	102	16	\N
10	102	17	\N
11	102	11	\N
12	212	20	\N
13	212	21	\N
14	213	22	\N
15	213	23	\N
16	117	3	\N
17	118	3	\N
18	118	24	\N
19	119	25	\N
20	119	17	\N
21	119	16	\N
22	120	25	\N
23	120	27	\N
24	103	14	\N
25	104	12	\N
26	121	16	\N
27	121	28	\N
28	121	17	\N
29	105	29	\N
30	105	30	\N
31	106	31	\N
32	106	18	\N
33	107	32	\N
34	108	33	\N
35	108	34	\N
36	109	35	\N
38	109	36	\N
39	110	36	\N
40	111	37	\N
41	111	36	\N
42	112	35	\N
43	113	9	\N
44	114	38	\N
45	114	18	\N
46	115	39	\N
47	115	40	\N
48	116	41	\N
49	116	42	\N
51	201	43	\N
52	201	44	\N
53	202	45	\N
54	202	46	\N
55	203	47	\N
56	203	49	\N
57	204	51	\N
58	204	52	\N
59	205	53	\N
60	205	54	\N
61	206	55	\N
62	207	56	\N
63	207	18	\N
64	208	57	\N
65	208	18	\N
66	209	46	\N
67	210	58	\N
68	210	59	\N
69	211	60	\N
70	211	61	\N
71	211	62	\N
72	211	63	\N
73	301	64	\N
74	301	65	\N
75	301	66	\N
76	302	67	\N
77	303	68	\N
78	303	69	\N
79	303	70	\N
80	303	71	\N
81	304	65	\N
82	304	66	\N
83	304	72	\N
84	304	73	\N
85	304	74	\N
86	304	75	\N
87	401	76	\N
88	401	77	\N
89	401	78	\N
90	401	79	\N
91	401	80	\N
92	401	81	\N
93	402	6	\N
94	403	76	\N
95	403	82	\N
96	305	83	\N
97	305	81	\N
98	305	84	\N
99	305	80	\N
114	214	83	\N
115	122	85	\N
116	122	86	\N
117	122	37	\N
118	122	16	\N
119	123	87	\N
120	123	88	\N
121	123	16	\N
122	404	21	\N
123	404	89	\N
124	124	90	\N
125	124	91	\N
126	125	92	\N
127	126	50	\N
128	126	52	\N
129	126	51	\N
130	126	85	\N
131	127	85	\N
132	127	93	\N
133	215	94	\N
134	128	31	\N
135	128	95	\N
136	129	30	\N
137	129	96	\N
138	129	97	\N
139	130	98	\N
140	131	37	\N
141	131	99	\N
142	132	100	\N
143	132	101	\N
144	133	102	\N
145	133	103	\N
146	134	102	\N
147	134	40	\N
148	135	102	\N
149	135	97	\N
150	136	104	\N
151	136	105	\N
152	136	106	\N
153	137	107	\N
154	137	108	\N
155	138	109	\N
156	139	55	\N
157	139	37	\N
158	140	13	\N
159	141	13	\N
160	141	110	\N
161	142	8	\N
162	143	111	\N
163	143	8	\N
164	144	112	\N
165	144	113	\N
166	145	114	\N
167	145	58	\N
168	146	15	\N
169	147	103	\N
170	147	80	\N
171	148	15	\N
172	149	15	\N
173	150	15	\N
174	150	115	\N
175	151	31	\N
176	151	95	\N
177	152	116	\N
178	153	80	\N
179	153	51	\N
180	153	110	\N
181	153	111	\N
182	154	117	\N
183	154	118	\N
184	155	119	\N
185	155	120	\N
186	155	121	\N
187	216	122	\N
188	217	123	\N
189	217	124	\N
190	218	119	\N
191	218	125	\N
192	219	126	\N
193	220	127	\N
194	220	124	\N
195	220	128	\N
196	220	46	\N
197	221	124	\N
198	221	83	\N
199	222	129	\N
200	222	113	\N
201	223	130	\N
202	223	43	\N
203	224	47	\N
204	224	131	\N
205	225	132	\N
206	306	133	\N
207	306	134	\N
208	307	119	\N
209	307	135	\N
210	308	136	\N
211	308	37	\N
212	308	137	\N
\.


--
-- Name: t_s_id_seq; Type: SEQUENCE SET; Schema: public; Owner: rongchenxuan
--

SELECT pg_catalog.setval('t_s_id_seq', 212, true);


--
-- Name: history history_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY history
    ADD CONSTRAINT history_pkey PRIMARY KEY (id);


--
-- Name: t_c t_c_pkey; Type: CONSTRAINT; Schema: public; Owner: rongchenxuan
--

ALTER TABLE ONLY t_c
    ADD CONSTRAINT t_c_pkey PRIMARY KEY (id);


--
-- Name: t_p t_p_pkey; Type: CONSTRAINT; Schema: public; Owner: rongchenxuan
--

ALTER TABLE ONLY t_p
    ADD CONSTRAINT t_p_pkey PRIMARY KEY (id);


--
-- Name: t_s t_s_pkey; Type: CONSTRAINT; Schema: public; Owner: rongchenxuan
--

ALTER TABLE ONLY t_s
    ADD CONSTRAINT t_s_pkey PRIMARY KEY (id);


--
-- Name: fki_s_cid; Type: INDEX; Schema: public; Owner: rongchenxuan
--

CREATE INDEX fki_s_cid ON t_s USING btree (c_id);


--
-- Name: fki_s_pid; Type: INDEX; Schema: public; Owner: rongchenxuan
--

CREATE INDEX fki_s_pid ON t_s USING btree (p_id);


--
-- Name: t_s s_cid; Type: FK CONSTRAINT; Schema: public; Owner: rongchenxuan
--

ALTER TABLE ONLY t_s
    ADD CONSTRAINT s_cid FOREIGN KEY (c_id) REFERENCES t_c(id);


--
-- Name: t_s s_pid; Type: FK CONSTRAINT; Schema: public; Owner: rongchenxuan
--

ALTER TABLE ONLY t_s
    ADD CONSTRAINT s_pid FOREIGN KEY (p_id) REFERENCES t_p(id);


--
-- PostgreSQL database dump complete
--

