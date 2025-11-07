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

--
-- Name: unaccent; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS unaccent WITH SCHEMA public;


--
-- Name: privacy; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.privacy AS ENUM (
    'public',
    'friend & family',
    'private'
);


--
-- Name: tag_source; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.tag_source AS ENUM (
    'photonia',
    'flickr',
    'rekognition'
);


--
-- Name: photos_trigger(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.photos_trigger() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ declare photo_tags record; photo_albums record; begin select string_agg(tags.name, ' ') as name into photo_tags from tags inner join taggings on tags.id = taggings.tag_id where taggings.taggable_id = new.id and taggings.taggable_type = 'Photo' and taggings.context = 'tags'; select string_agg(albums.title, ' ') as title into photo_albums from albums inner join albums_photos on albums.id = albums_photos.album_id where albums_photos.photo_id = new.id; new.tsv := setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(new.title, ''))), 'A') || setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(new.description, ''))), 'A') || setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(photo_tags.name, ''))), 'B') || setweight(to_tsvector('pg_catalog.english', unaccent(coalesce(photo_albums.title, ''))), 'B'); return new; end $$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: albums; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.albums (
    id bigint NOT NULL,
    slug character varying,
    title character varying,
    description text,
    serial_number bigint,
    flickr_impressions_count integer DEFAULT 0 NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    impressions_count integer DEFAULT 0 NOT NULL,
    user_id bigint DEFAULT 1 NOT NULL,
    public_cover_photo_id bigint,
    user_cover_photo_id bigint,
    public_photos_count integer DEFAULT 0 NOT NULL,
    photos_count integer DEFAULT 0 NOT NULL,
    privacy public.privacy DEFAULT 'public'::public.privacy,
    description_html text,
    sorting_type character varying DEFAULT 'taken_at'::character varying NOT NULL,
    sorting_order character varying DEFAULT 'asc'::character varying NOT NULL
);


--
-- Name: albums_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.albums_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: albums_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.albums_id_seq OWNED BY public.albums.id;


--
-- Name: albums_photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.albums_photos (
    id bigint NOT NULL,
    album_id bigint NOT NULL,
    photo_id bigint NOT NULL,
    ordering integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: albums_photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.albums_photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: albums_photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.albums_photos_id_seq OWNED BY public.albums_photos.id;


--
-- Name: ar_internal_metadata; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ar_internal_metadata (
    key character varying NOT NULL,
    value character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comments; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.comments (
    id bigint NOT NULL,
    serial_number bigint,
    commentable_type character varying NOT NULL,
    commentable_id bigint NOT NULL,
    user_id bigint,
    flickr_user_id bigint,
    flickr_link character varying,
    body text,
    body_html text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: comments_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: comments_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.comments_id_seq OWNED BY public.comments.id;


--
-- Name: flickr_user_claims; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flickr_user_claims (
    id bigint NOT NULL,
    user_id bigint NOT NULL,
    flickr_user_id bigint NOT NULL,
    claim_type character varying NOT NULL,
    status character varying DEFAULT 'pending'::character varying NOT NULL,
    verification_code character varying,
    reason text,
    verified_at timestamp(6) without time zone,
    approved_at timestamp(6) without time zone,
    denied_at timestamp(6) without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: flickr_user_claims_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flickr_user_claims_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flickr_user_claims_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flickr_user_claims_id_seq OWNED BY public.flickr_user_claims.id;


--
-- Name: flickr_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.flickr_users (
    id bigint NOT NULL,
    nsid character varying,
    is_deleted boolean,
    iconserver character varying,
    iconfarm character varying,
    username character varying,
    realname character varying,
    location character varying,
    timezone_label character varying,
    timezone_offset character varying,
    timezone_id character varying,
    description text,
    photosurl character varying,
    profileurl character varying,
    photos_firstdatetaken character varying,
    photos_firstdate integer,
    photos_count integer,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    claimed_by_user_id bigint
);


--
-- Name: flickr_users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.flickr_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: flickr_users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.flickr_users_id_seq OWNED BY public.flickr_users.id;


--
-- Name: friendly_id_slugs; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.friendly_id_slugs (
    id bigint NOT NULL,
    slug character varying NOT NULL,
    sluggable_id integer NOT NULL,
    sluggable_type character varying(50),
    scope character varying,
    created_at timestamp without time zone
);


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.friendly_id_slugs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: friendly_id_slugs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.friendly_id_slugs_id_seq OWNED BY public.friendly_id_slugs.id;


--
-- Name: impressions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.impressions (
    id bigint NOT NULL,
    impressionable_type character varying,
    impressionable_id integer,
    user_id integer,
    controller_name character varying,
    action_name character varying,
    view_name character varying,
    request_hash character varying,
    ip_address character varying,
    session_hash character varying,
    message text,
    referrer text,
    params text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: impressions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.impressions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: impressions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.impressions_id_seq OWNED BY public.impressions.id;


--
-- Name: labels; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.labels (
    id bigint NOT NULL,
    photo_id bigint NOT NULL,
    name character varying,
    confidence double precision,
    top double precision,
    "left" double precision,
    width double precision,
    height double precision,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: labels_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.labels_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: labels_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.labels_id_seq OWNED BY public.labels.id;


--
-- Name: photos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.photos (
    id bigint NOT NULL,
    slug character varying,
    title character varying,
    description text,
    taken_at timestamp without time zone,
    license character varying,
    exif jsonb,
    serial_number bigint NOT NULL,
    flickr_impressions_count integer DEFAULT 0 NOT NULL,
    flickr_faves integer,
    posted_at timestamp without time zone,
    flickr_photopage character varying,
    flickr_original character varying,
    image_data jsonb,
    flickr_json jsonb,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    privacy public.privacy DEFAULT 'public'::public.privacy,
    rekognition_response jsonb,
    user_id bigint,
    tsv tsvector,
    impressions_count integer DEFAULT 0 NOT NULL,
    timezone character varying DEFAULT 'UTC'::character varying NOT NULL,
    taken_at_from_exif boolean DEFAULT false,
    description_html text
);


--
-- Name: photos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.photos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: photos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.photos_id_seq OWNED BY public.photos.id;


--
-- Name: related_tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.related_tags (
    id bigint NOT NULL,
    tag_id_from bigint NOT NULL,
    tag_id_to bigint NOT NULL,
    support integer NOT NULL,
    support_from integer NOT NULL,
    support_to integer NOT NULL,
    confidence double precision NOT NULL,
    lift double precision NOT NULL,
    jaccard double precision NOT NULL,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: related_tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.related_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: related_tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.related_tags_id_seq OWNED BY public.related_tags.id;


--
-- Name: roles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles (
    id bigint NOT NULL,
    name character varying,
    symbol character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: roles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.roles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: roles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.roles_id_seq OWNED BY public.roles.id;


--
-- Name: roles_users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.roles_users (
    user_id bigint NOT NULL,
    role_id bigint NOT NULL
);


--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.schema_migrations (
    version character varying NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.settings (
    id bigint NOT NULL,
    var character varying NOT NULL,
    value text,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.settings_id_seq OWNED BY public.settings.id;


--
-- Name: tagging_sources; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tagging_sources (
    id bigint NOT NULL,
    name character varying,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL
);


--
-- Name: tagging_sources_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tagging_sources_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tagging_sources_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tagging_sources_id_seq OWNED BY public.tagging_sources.id;


--
-- Name: taggings; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_type character varying,
    taggable_id integer,
    tagger_type character varying,
    tagger_id integer,
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.taggings_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.taggings_id_seq OWNED BY public.taggings.id;


--
-- Name: tags; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tags (
    id integer NOT NULL,
    name character varying,
    created_at timestamp without time zone,
    updated_at timestamp without time zone,
    taggings_count integer DEFAULT 0,
    source public.tag_source DEFAULT 'photonia'::public.tag_source,
    slug character varying,
    impressions_count integer DEFAULT 0 NOT NULL
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tags_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tags_id_seq OWNED BY public.tags.id;


--
-- Name: users; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.users (
    id bigint NOT NULL,
    email character varying DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying DEFAULT ''::character varying NOT NULL,
    remember_created_at timestamp without time zone,
    created_at timestamp(6) without time zone NOT NULL,
    updated_at timestamp(6) without time zone NOT NULL,
    jti character varying,
    timezone character varying DEFAULT 'UTC'::character varying NOT NULL,
    admin boolean DEFAULT false,
    first_name character varying,
    last_name character varying,
    display_name character varying,
    serial_number bigint,
    slug character varying,
    signup_provider character varying DEFAULT 'local'::character varying NOT NULL,
    facebook_user_id character varying,
    created_from_facebook boolean DEFAULT false NOT NULL,
    facebook_data_deletion_code character varying,
    disabled boolean DEFAULT false NOT NULL,
    default_license character varying
);


--
-- Name: users_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.users_id_seq OWNED BY public.users.id;


--
-- Name: versions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.versions (
    id bigint NOT NULL,
    whodunnit character varying,
    created_at timestamp(6) without time zone,
    item_id bigint NOT NULL,
    item_type character varying NOT NULL,
    event character varying NOT NULL,
    object text,
    object_changes jsonb
);


--
-- Name: versions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.versions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: versions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.versions_id_seq OWNED BY public.versions.id;


--
-- Name: albums id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums ALTER COLUMN id SET DEFAULT nextval('public.albums_id_seq'::regclass);


--
-- Name: albums_photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums_photos ALTER COLUMN id SET DEFAULT nextval('public.albums_photos_id_seq'::regclass);


--
-- Name: comments id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments ALTER COLUMN id SET DEFAULT nextval('public.comments_id_seq'::regclass);


--
-- Name: flickr_user_claims id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_user_claims ALTER COLUMN id SET DEFAULT nextval('public.flickr_user_claims_id_seq'::regclass);


--
-- Name: flickr_users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_users ALTER COLUMN id SET DEFAULT nextval('public.flickr_users_id_seq'::regclass);


--
-- Name: friendly_id_slugs id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs ALTER COLUMN id SET DEFAULT nextval('public.friendly_id_slugs_id_seq'::regclass);


--
-- Name: impressions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressions ALTER COLUMN id SET DEFAULT nextval('public.impressions_id_seq'::regclass);


--
-- Name: labels id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels ALTER COLUMN id SET DEFAULT nextval('public.labels_id_seq'::regclass);


--
-- Name: photos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photos ALTER COLUMN id SET DEFAULT nextval('public.photos_id_seq'::regclass);


--
-- Name: related_tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.related_tags ALTER COLUMN id SET DEFAULT nextval('public.related_tags_id_seq'::regclass);


--
-- Name: roles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles ALTER COLUMN id SET DEFAULT nextval('public.roles_id_seq'::regclass);


--
-- Name: settings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings ALTER COLUMN id SET DEFAULT nextval('public.settings_id_seq'::regclass);


--
-- Name: tagging_sources id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tagging_sources ALTER COLUMN id SET DEFAULT nextval('public.tagging_sources_id_seq'::regclass);


--
-- Name: taggings id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings ALTER COLUMN id SET DEFAULT nextval('public.taggings_id_seq'::regclass);


--
-- Name: tags id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags ALTER COLUMN id SET DEFAULT nextval('public.tags_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users ALTER COLUMN id SET DEFAULT nextval('public.users_id_seq'::regclass);


--
-- Name: versions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions ALTER COLUMN id SET DEFAULT nextval('public.versions_id_seq'::regclass);


--
-- Name: albums_photos albums_photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums_photos
    ADD CONSTRAINT albums_photos_pkey PRIMARY KEY (id);


--
-- Name: albums albums_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT albums_pkey PRIMARY KEY (id);


--
-- Name: ar_internal_metadata ar_internal_metadata_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ar_internal_metadata
    ADD CONSTRAINT ar_internal_metadata_pkey PRIMARY KEY (key);


--
-- Name: comments comments_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT comments_pkey PRIMARY KEY (id);


--
-- Name: flickr_user_claims flickr_user_claims_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_user_claims
    ADD CONSTRAINT flickr_user_claims_pkey PRIMARY KEY (id);


--
-- Name: flickr_users flickr_users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_users
    ADD CONSTRAINT flickr_users_pkey PRIMARY KEY (id);


--
-- Name: friendly_id_slugs friendly_id_slugs_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.friendly_id_slugs
    ADD CONSTRAINT friendly_id_slugs_pkey PRIMARY KEY (id);


--
-- Name: impressions impressions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.impressions
    ADD CONSTRAINT impressions_pkey PRIMARY KEY (id);


--
-- Name: labels labels_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT labels_pkey PRIMARY KEY (id);


--
-- Name: photos photos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photos
    ADD CONSTRAINT photos_pkey PRIMARY KEY (id);


--
-- Name: related_tags related_tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.related_tags
    ADD CONSTRAINT related_tags_pkey PRIMARY KEY (id);


--
-- Name: roles roles_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.roles
    ADD CONSTRAINT roles_pkey PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settings settings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.settings
    ADD CONSTRAINT settings_pkey PRIMARY KEY (id);


--
-- Name: tagging_sources tagging_sources_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tagging_sources
    ADD CONSTRAINT tagging_sources_pkey PRIMARY KEY (id);


--
-- Name: taggings taggings_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags tags_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: versions versions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.versions
    ADD CONSTRAINT versions_pkey PRIMARY KEY (id);


--
-- Name: controlleraction_ip_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX controlleraction_ip_index ON public.impressions USING btree (controller_name, action_name, ip_address);


--
-- Name: controlleraction_request_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX controlleraction_request_index ON public.impressions USING btree (controller_name, action_name, request_hash);


--
-- Name: controlleraction_session_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX controlleraction_session_index ON public.impressions USING btree (controller_name, action_name, session_hash);


--
-- Name: impressionable_type_message_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX impressionable_type_message_index ON public.impressions USING btree (impressionable_type, message, impressionable_id);


--
-- Name: index_albums_on_public_cover_photo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_albums_on_public_cover_photo_id ON public.albums USING btree (public_cover_photo_id);


--
-- Name: index_albums_on_user_cover_photo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_albums_on_user_cover_photo_id ON public.albums USING btree (user_cover_photo_id);


--
-- Name: index_albums_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_albums_on_user_id ON public.albums USING btree (user_id);


--
-- Name: index_albums_photos_on_album_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_albums_photos_on_album_id ON public.albums_photos USING btree (album_id);


--
-- Name: index_albums_photos_on_photo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_albums_photos_on_photo_id ON public.albums_photos USING btree (photo_id);


--
-- Name: index_comments_on_commentable; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_commentable ON public.comments USING btree (commentable_type, commentable_id);


--
-- Name: index_comments_on_flickr_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_flickr_user_id ON public.comments USING btree (flickr_user_id);


--
-- Name: index_comments_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_comments_on_user_id ON public.comments USING btree (user_id);


--
-- Name: index_flickr_user_claims_on_flickr_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flickr_user_claims_on_flickr_user_id ON public.flickr_user_claims USING btree (flickr_user_id);


--
-- Name: index_flickr_user_claims_on_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flickr_user_claims_on_status ON public.flickr_user_claims USING btree (status);


--
-- Name: index_flickr_user_claims_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flickr_user_claims_on_user_id ON public.flickr_user_claims USING btree (user_id);


--
-- Name: index_flickr_user_claims_on_user_id_and_flickr_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_flickr_user_claims_on_user_id_and_flickr_user_id ON public.flickr_user_claims USING btree (user_id, flickr_user_id);


--
-- Name: index_flickr_users_on_claimed_by_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_flickr_users_on_claimed_by_user_id ON public.flickr_users USING btree (claimed_by_user_id);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type ON public.friendly_id_slugs USING btree (slug, sluggable_type);


--
-- Name: index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope ON public.friendly_id_slugs USING btree (slug, sluggable_type, scope);


--
-- Name: index_friendly_id_slugs_on_sluggable_type_and_sluggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_friendly_id_slugs_on_sluggable_type_and_sluggable_id ON public.friendly_id_slugs USING btree (sluggable_type, sluggable_id);


--
-- Name: index_impressions_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_impressions_on_user_id ON public.impressions USING btree (user_id);


--
-- Name: index_labels_on_photo_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_labels_on_photo_id ON public.labels USING btree (photo_id);


--
-- Name: index_photos_on_exif; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_photos_on_exif ON public.photos USING gin (exif);


--
-- Name: index_photos_on_rekognition_response; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_photos_on_rekognition_response ON public.photos USING gin (rekognition_response);


--
-- Name: index_photos_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_photos_on_slug ON public.photos USING btree (slug);


--
-- Name: index_photos_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_photos_on_user_id ON public.photos USING btree (user_id);


--
-- Name: index_related_tags_on_tag_id_from_and_tag_id_to; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_related_tags_on_tag_id_from_and_tag_id_to ON public.related_tags USING btree (tag_id_from, tag_id_to);


--
-- Name: index_related_tags_on_tag_id_to; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_related_tags_on_tag_id_to ON public.related_tags USING btree (tag_id_to);


--
-- Name: index_roles_users_on_role_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_users_on_role_id ON public.roles_users USING btree (role_id);


--
-- Name: index_roles_users_on_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_roles_users_on_user_id ON public.roles_users USING btree (user_id);


--
-- Name: index_settings_on_var; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_settings_on_var ON public.settings USING btree (var);


--
-- Name: index_taggings_on_context; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_context ON public.taggings USING btree (context);


--
-- Name: index_taggings_on_tag_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tag_id ON public.taggings USING btree (tag_id);


--
-- Name: index_taggings_on_taggable_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_id ON public.taggings USING btree (taggable_id);


--
-- Name: index_taggings_on_taggable_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_taggable_type ON public.taggings USING btree (taggable_type);


--
-- Name: index_taggings_on_tagger_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id ON public.taggings USING btree (tagger_id);


--
-- Name: index_taggings_on_tagger_id_and_tagger_type; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_taggings_on_tagger_id_and_tagger_type ON public.taggings USING btree (tagger_id, tagger_type);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_name ON public.tags USING btree (name);


--
-- Name: index_tags_on_slug; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_tags_on_slug ON public.tags USING btree (slug);


--
-- Name: index_users_on_email; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_email ON public.users USING btree (email);


--
-- Name: index_users_on_facebook_data_deletion_code; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_facebook_data_deletion_code ON public.users USING btree (facebook_data_deletion_code);


--
-- Name: index_users_on_facebook_user_id; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_facebook_user_id ON public.users USING btree (facebook_user_id);


--
-- Name: index_users_on_jti; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX index_users_on_jti ON public.users USING btree (jti);


--
-- Name: index_versions_on_item_type_and_item_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX index_versions_on_item_type_and_item_id ON public.versions USING btree (item_type, item_id);


--
-- Name: poly_ip_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX poly_ip_index ON public.impressions USING btree (impressionable_type, impressionable_id, ip_address);


--
-- Name: poly_params_request_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX poly_params_request_index ON public.impressions USING btree (impressionable_type, impressionable_id, params);


--
-- Name: poly_request_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX poly_request_index ON public.impressions USING btree (impressionable_type, impressionable_id, request_hash);


--
-- Name: poly_session_index; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX poly_session_index ON public.impressions USING btree (impressionable_type, impressionable_id, session_hash);


--
-- Name: taggings_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX taggings_idx ON public.taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: taggings_idy; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_idy ON public.taggings USING btree (taggable_id, taggable_type, tagger_id, context);


--
-- Name: taggings_taggable_context_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_taggable_context_idx ON public.taggings USING btree (taggable_id, taggable_type, context);


--
-- Name: taggings_tagger_idx; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX taggings_tagger_idx ON public.taggings USING btree (tagger_id, tagger_type);


--
-- Name: photos tsvupdate; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER tsvupdate BEFORE INSERT OR UPDATE ON public.photos FOR EACH ROW EXECUTE FUNCTION public.photos_trigger();


--
-- Name: comments fk_rails_03de2dc08c; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_03de2dc08c FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: flickr_users fk_rails_06c7d2d8a1; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_users
    ADD CONSTRAINT fk_rails_06c7d2d8a1 FOREIGN KEY (claimed_by_user_id) REFERENCES public.users(id);


--
-- Name: comments fk_rails_2d3346c513; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.comments
    ADD CONSTRAINT fk_rails_2d3346c513 FOREIGN KEY (flickr_user_id) REFERENCES public.flickr_users(id);


--
-- Name: flickr_user_claims fk_rails_2d65221cc2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_user_claims
    ADD CONSTRAINT fk_rails_2d65221cc2 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: related_tags fk_rails_3e066e44b2; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.related_tags
    ADD CONSTRAINT fk_rails_3e066e44b2 FOREIGN KEY (tag_id_to) REFERENCES public.tags(id);


--
-- Name: labels fk_rails_6e98447d68; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.labels
    ADD CONSTRAINT fk_rails_6e98447d68 FOREIGN KEY (photo_id) REFERENCES public.photos(id);


--
-- Name: albums fk_rails_964016e0e8; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums
    ADD CONSTRAINT fk_rails_964016e0e8 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: taggings fk_rails_9fcd2e236b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.taggings
    ADD CONSTRAINT fk_rails_9fcd2e236b FOREIGN KEY (tag_id) REFERENCES public.tags(id);


--
-- Name: flickr_user_claims fk_rails_b1f948be98; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.flickr_user_claims
    ADD CONSTRAINT fk_rails_b1f948be98 FOREIGN KEY (flickr_user_id) REFERENCES public.flickr_users(id);


--
-- Name: related_tags fk_rails_b9624a660e; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.related_tags
    ADD CONSTRAINT fk_rails_b9624a660e FOREIGN KEY (tag_id_from) REFERENCES public.tags(id);


--
-- Name: photos fk_rails_c79d76afc0; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.photos
    ADD CONSTRAINT fk_rails_c79d76afc0 FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- Name: albums_photos fk_rails_cf9aac895b; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums_photos
    ADD CONSTRAINT fk_rails_cf9aac895b FOREIGN KEY (photo_id) REFERENCES public.photos(id);


--
-- Name: albums_photos fk_rails_eb249493ab; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.albums_photos
    ADD CONSTRAINT fk_rails_eb249493ab FOREIGN KEY (album_id) REFERENCES public.albums(id);


--
-- PostgreSQL database dump complete
--

SET search_path TO "$user", public;

INSERT INTO "schema_migrations" (version) VALUES
('20251107000001'),
('20251106121510'),
('20251105154000'),
('20251105153946'),
('20251103153701'),
('20251103135206'),
('20251021101306'),
('20250919125004'),
('20250822171155'),
('20241223145106'),
('20241223145105'),
('20241115114702'),
('20241115114615'),
('20241115100214'),
('20241031094724'),
('20241016142426'),
('20240627150304'),
('20240627150254'),
('20240515124115'),
('20240321083201'),
('20240320150852'),
('20240319074139'),
('20240319073415'),
('20240318152358'),
('20240315100311'),
('20240315095159'),
('20231107090606'),
('20231107090043'),
('20231107075611'),
('20231107073727'),
('20231106215849'),
('20231105152447'),
('20231015122407'),
('20231015122341'),
('20231015101852'),
('20230712191829'),
('20230410080845'),
('20230410080718'),
('20230409184758'),
('20230409171819'),
('20230409171752'),
('20230409165520'),
('20230403133751'),
('20230328161122'),
('20230319213544'),
('20230319213543'),
('20230319213542'),
('20221111194506'),
('20210823184309'),
('20210109214524'),
('20210109204633'),
('20210109083341'),
('20210108215322'),
('20210104115821'),
('20210103163930'),
('20210103163610'),
('20201230100525'),
('20201229212934'),
('20201229211939'),
('20201229204909'),
('20201226180141'),
('20201226121349'),
('20201202144952'),
('20201202140044'),
('20201202140043'),
('20201129204208'),
('20201129084036'),
('20201129082610'),
('20201127215926'),
('20201127215925'),
('20201127215924'),
('20201127215923'),
('20201127215922'),
('20201127215921'),
('20201127201610'),
('20201126064043'),
('20201125121839');

