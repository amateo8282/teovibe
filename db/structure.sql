CREATE TABLE IF NOT EXISTS "schema_migrations" ("version" varchar NOT NULL PRIMARY KEY);
CREATE TABLE IF NOT EXISTS "ar_internal_metadata" ("key" varchar NOT NULL PRIMARY KEY, "value" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE TABLE IF NOT EXISTS "users" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "email_address" varchar NOT NULL, "password_digest" varchar NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "nickname" varchar DEFAULT '' NOT NULL /*application='Teovibe'*/, "avatar_url" varchar /*application='Teovibe'*/, "bio" text /*application='Teovibe'*/, "role" integer DEFAULT 0 NOT NULL /*application='Teovibe'*/, "points" integer DEFAULT 0 NOT NULL /*application='Teovibe'*/, "level" integer DEFAULT 1 NOT NULL /*application='Teovibe'*/, "posts_count" integer DEFAULT 0 NOT NULL /*application='Teovibe'*/, "comments_count" integer DEFAULT 0 NOT NULL /*application='Teovibe'*/, "github_url" varchar /*application='Teovibe'*/, "twitter_url" varchar /*application='Teovibe'*/, "website_url" varchar /*application='Teovibe'*/, "payment_customer_key" varchar /*application='Teovibe'*/);
CREATE UNIQUE INDEX "index_users_on_email_address" ON "users" ("email_address") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "sessions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "ip_address" varchar, "user_agent" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_758836b4f0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_sessions_on_user_id" ON "sessions" ("user_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "connected_services" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "provider" varchar, "uid" varchar, "access_token" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_006b937ba0"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_connected_services_on_user_id" ON "connected_services" ("user_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "comments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "post_id" integer NOT NULL, "parent_id" integer, "body" text NOT NULL, "accepted" boolean DEFAULT FALSE NOT NULL, "likes_count" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_03de2dc08c"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_2fd19c0db7"
FOREIGN KEY ("post_id")
  REFERENCES "posts" ("id")
, CONSTRAINT "fk_rails_31554e7034"
FOREIGN KEY ("parent_id")
  REFERENCES "comments" ("id")
);
CREATE INDEX "index_comments_on_user_id" ON "comments" ("user_id") /*application='Teovibe'*/;
CREATE INDEX "index_comments_on_post_id" ON "comments" ("post_id") /*application='Teovibe'*/;
CREATE INDEX "index_comments_on_parent_id" ON "comments" ("parent_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "likes" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "likeable_type" varchar NOT NULL, "likeable_id" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_1e09b5dabf"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_likes_on_user_id" ON "likes" ("user_id") /*application='Teovibe'*/;
CREATE INDEX "index_likes_on_likeable" ON "likes" ("likeable_type", "likeable_id") /*application='Teovibe'*/;
CREATE UNIQUE INDEX "index_likes_on_user_id_and_likeable_type_and_likeable_id" ON "likes" ("user_id", "likeable_type", "likeable_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "landing_sections" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "section_type" integer DEFAULT 0 NOT NULL, "title" varchar NOT NULL, "subtitle" text, "position" integer DEFAULT 0 NOT NULL, "active" boolean DEFAULT TRUE NOT NULL, "background_color" varchar, "text_color" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_landing_sections_on_position" ON "landing_sections" ("position") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "section_cards" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "landing_section_id" integer NOT NULL, "title" varchar, "description" text, "icon" varchar, "link_url" varchar, "link_text" varchar, "position" integer, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_45b0975efd"
FOREIGN KEY ("landing_section_id")
  REFERENCES "landing_sections" ("id")
);
CREATE INDEX "index_section_cards_on_landing_section_id" ON "section_cards" ("landing_section_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "active_storage_blobs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "key" varchar NOT NULL, "filename" varchar NOT NULL, "content_type" varchar, "metadata" text, "service_name" varchar NOT NULL, "byte_size" bigint NOT NULL, "checksum" varchar, "created_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_active_storage_blobs_on_key" ON "active_storage_blobs" ("key") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "active_storage_attachments" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "blob_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_c3b3935057"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE INDEX "index_active_storage_attachments_on_blob_id" ON "active_storage_attachments" ("blob_id") /*application='Teovibe'*/;
CREATE UNIQUE INDEX "index_active_storage_attachments_uniqueness" ON "active_storage_attachments" ("record_type", "record_id", "name", "blob_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "active_storage_variant_records" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "blob_id" bigint NOT NULL, "variation_digest" varchar NOT NULL, CONSTRAINT "fk_rails_993965df05"
FOREIGN KEY ("blob_id")
  REFERENCES "active_storage_blobs" ("id")
);
CREATE UNIQUE INDEX "index_active_storage_variant_records_uniqueness" ON "active_storage_variant_records" ("blob_id", "variation_digest") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "action_text_rich_texts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "body" text, "record_type" varchar NOT NULL, "record_id" bigint NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_action_text_rich_texts_uniqueness" ON "action_text_rich_texts" ("record_type", "record_id", "name") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "downloads" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "skill_pack_id" integer NOT NULL, "ip_address" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_0cd58e10e1"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_05da6d5a69"
FOREIGN KEY ("skill_pack_id")
  REFERENCES "skill_packs" ("id")
);
CREATE INDEX "index_downloads_on_user_id" ON "downloads" ("user_id") /*application='Teovibe'*/;
CREATE INDEX "index_downloads_on_skill_pack_id" ON "downloads" ("skill_pack_id") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "inquiries" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "email" varchar NOT NULL, "phone" varchar, "company" varchar, "subject" varchar NOT NULL, "body" text NOT NULL, "status" integer DEFAULT 0 NOT NULL, "admin_reply" text, "replied_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE INDEX "index_inquiries_on_status" ON "inquiries" ("status") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "point_transactions" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "amount" integer NOT NULL, "action_type" integer NOT NULL, "pointable_type" varchar, "pointable_id" integer, "description" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_fc956f9f03"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_point_transactions_on_user_id" ON "point_transactions" ("user_id") /*application='Teovibe'*/;
CREATE INDEX "index_point_transactions_on_pointable" ON "point_transactions" ("pointable_type", "pointable_id") /*application='Teovibe'*/;
CREATE INDEX "index_point_transactions_on_action_type" ON "point_transactions" ("action_type") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "notifications" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "actor_id" integer, "notifiable_type" varchar, "notifiable_id" integer, "notification_type" integer DEFAULT 0 NOT NULL, "read" boolean DEFAULT FALSE NOT NULL, "read_at" datetime(6), "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_b080fb4855"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_06a39bb8cc"
FOREIGN KEY ("actor_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_notifications_on_user_id" ON "notifications" ("user_id") /*application='Teovibe'*/;
CREATE INDEX "index_notifications_on_notifiable" ON "notifications" ("notifiable_type", "notifiable_id") /*application='Teovibe'*/;
CREATE INDEX "index_notifications_on_user_id_and_read" ON "notifications" ("user_id", "read") /*application='Teovibe'*/;
CREATE VIRTUAL TABLE posts_fts USING fts5(
        title, body, slug,
        content='posts',
        content_rowid='id'
      )
/* posts_fts(title,body,slug) */;
CREATE TABLE IF NOT EXISTS 'posts_fts_data'(id INTEGER PRIMARY KEY, block BLOB);
CREATE TABLE IF NOT EXISTS 'posts_fts_idx'(segid, term, pgno, PRIMARY KEY(segid, term)) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS 'posts_fts_docsize'(id INTEGER PRIMARY KEY, sz BLOB);
CREATE TABLE IF NOT EXISTS 'posts_fts_config'(k PRIMARY KEY, v) WITHOUT ROWID;
CREATE TABLE IF NOT EXISTS "orders" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "skill_pack_id" integer NOT NULL, "status" integer DEFAULT 0 NOT NULL, "toss_order_id" varchar NOT NULL, "payment_event_id" varchar, "amount" integer NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, CONSTRAINT "fk_rails_f868b47f6a"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
, CONSTRAINT "fk_rails_c2d59fb3f2"
FOREIGN KEY ("skill_pack_id")
  REFERENCES "skill_packs" ("id")
);
CREATE INDEX "index_orders_on_user_id" ON "orders" ("user_id") /*application='Teovibe'*/;
CREATE INDEX "index_orders_on_skill_pack_id" ON "orders" ("skill_pack_id") /*application='Teovibe'*/;
CREATE UNIQUE INDEX "index_orders_on_toss_order_id" ON "orders" ("toss_order_id") /*application='Teovibe'*/;
CREATE UNIQUE INDEX "index_orders_on_payment_event_id" ON "orders" ("payment_event_id") WHERE payment_event_id IS NOT NULL /*application='Teovibe'*/;
CREATE INDEX "index_orders_on_status" ON "orders" ("status") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "categories" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "name" varchar NOT NULL, "slug" varchar NOT NULL, "description" text, "record_type" integer DEFAULT 0 NOT NULL, "position" integer DEFAULT 0 NOT NULL, "admin_only" boolean DEFAULT FALSE NOT NULL, "visible_in_nav" boolean DEFAULT TRUE NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL);
CREATE UNIQUE INDEX "index_categories_on_slug_and_record_type" ON "categories" ("slug", "record_type") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "posts" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "user_id" integer NOT NULL, "title" varchar NOT NULL, "slug" varchar, "status" integer DEFAULT 0 NOT NULL, "body" text, "pinned" boolean DEFAULT FALSE NOT NULL, "seo_title" varchar, "seo_description" text, "views_count" integer DEFAULT 0 NOT NULL, "likes_count" integer DEFAULT 0 NOT NULL, "comments_count" integer DEFAULT 0 NOT NULL, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "category_id" integer, "scheduled_at" datetime(6) /*application='Teovibe'*/, "job_id" varchar /*application='Teovibe'*/, CONSTRAINT "fk_rails_5b5ddfd518"
FOREIGN KEY ("user_id")
  REFERENCES "users" ("id")
);
CREATE INDEX "index_posts_on_user_id" ON "posts" ("user_id") /*application='Teovibe'*/;
CREATE UNIQUE INDEX "index_posts_on_slug" ON "posts" ("slug") /*application='Teovibe'*/;
CREATE INDEX "index_posts_on_status" ON "posts" ("status") /*application='Teovibe'*/;
CREATE TABLE IF NOT EXISTS "skill_packs" ("id" integer PRIMARY KEY AUTOINCREMENT NOT NULL, "title" varchar NOT NULL, "description" text, "download_token" varchar NOT NULL, "downloads_count" integer DEFAULT 0 NOT NULL, "status" integer DEFAULT 0 NOT NULL, "slug" varchar, "created_at" datetime(6) NOT NULL, "updated_at" datetime(6) NOT NULL, "price" integer DEFAULT 0 NOT NULL, "category_id" integer);
CREATE UNIQUE INDEX "index_skill_packs_on_download_token" ON "skill_packs" ("download_token") /*application='Teovibe'*/;
CREATE UNIQUE INDEX "index_skill_packs_on_slug" ON "skill_packs" ("slug") /*application='Teovibe'*/;
CREATE INDEX "index_skill_packs_on_status" ON "skill_packs" ("status") /*application='Teovibe'*/;
CREATE INDEX "index_posts_on_scheduled_at" ON "posts" ("scheduled_at") /*application='Teovibe'*/;
INSERT INTO "schema_migrations" (version) VALUES
('20260302132108'),
('20260228124813'),
('20260222102056'),
('20260222102044'),
('20260222102017'),
('20260222083121'),
('20260218063734'),
('20260218063719'),
('20260218063451'),
('20260218063223'),
('20260218062921'),
('20260218062916'),
('20260218054009'),
('20260218054008'),
('20260218053914'),
('20260218053913'),
('20260218053912'),
('20260218053911'),
('20260218053910'),
('20260218053909'),
('20260218053558'),
('20260218053553'),
('20260218053552');

