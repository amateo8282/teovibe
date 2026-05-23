# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_18_063734) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "comments", force: :cascade do |t|
    t.boolean "accepted", default: false, null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.integer "parent_id"
    t.integer "post_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "connected_services", force: :cascade do |t|
    t.string "access_token"
    t.datetime "created_at", null: false
    t.string "provider"
    t.string "uid"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_connected_services_on_user_id"
  end

  create_table "downloads", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.integer "skill_pack_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["skill_pack_id"], name: "index_downloads_on_skill_pack_id"
    t.index ["user_id"], name: "index_downloads_on_user_id"
  end

  create_table "inquiries", force: :cascade do |t|
    t.text "admin_reply"
    t.text "body", null: false
    t.string "company"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "replied_at"
    t.integer "status", default: 0, null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["status"], name: "index_inquiries_on_status"
  end

  create_table "landing_sections", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "background_color"
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.integer "section_type", default: 0, null: false
    t.text "subtitle"
    t.string "text_color"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["position"], name: "index_landing_sections_on_position"
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "likeable_id", null: false
    t.string "likeable_type", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["likeable_type", "likeable_id"], name: "index_likes_on_likeable"
    t.index ["user_id", "likeable_type", "likeable_id"], name: "index_likes_on_user_id_and_likeable_type_and_likeable_id", unique: true
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.integer "actor_id"
    t.datetime "created_at", null: false
    t.integer "notifiable_id"
    t.string "notifiable_type"
    t.integer "notification_type", default: 0, null: false
    t.boolean "read", default: false, null: false
    t.datetime "read_at"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id", "read"], name: "index_notifications_on_user_id_and_read"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "point_transactions", force: :cascade do |t|
    t.integer "action_type", null: false
    t.integer "amount", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.integer "pointable_id"
    t.string "pointable_type"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["action_type"], name: "index_point_transactions_on_action_type"
    t.index ["pointable_type", "pointable_id"], name: "index_point_transactions_on_pointable"
    t.index ["user_id"], name: "index_point_transactions_on_user_id"
  end

  create_table "posts", force: :cascade do |t|
    t.text "body"
    t.integer "category", default: 0, null: false
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "likes_count", default: 0, null: false
    t.boolean "pinned", default: false, null: false
    t.text "seo_description"
    t.string "seo_title"
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["category"], name: "index_posts_on_category"
    t.index ["slug"], name: "index_posts_on_slug", unique: true
    t.index ["status"], name: "index_posts_on_status"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "section_cards", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.integer "landing_section_id", null: false
    t.string "link_text"
    t.string "link_url"
    t.integer "position"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["landing_section_id"], name: "index_section_cards_on_landing_section_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "skill_packs", force: :cascade do |t|
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "download_token", null: false
    t.integer "downloads_count", default: 0, null: false
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_skill_packs_on_category"
    t.index ["download_token"], name: "index_skill_packs_on_download_token", unique: true
    t.index ["slug"], name: "index_skill_packs_on_slug", unique: true
    t.index ["status"], name: "index_skill_packs_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.text "bio"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.integer "level", default: 1, null: false
    t.string "nickname", default: "", null: false
    t.string "password_digest", null: false
    t.integer "points", default: 0, null: false
    t.integer "posts_count", default: 0, null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "connected_services", "users"
  add_foreign_key "downloads", "skill_packs"
  add_foreign_key "downloads", "users"
  add_foreign_key "likes", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "point_transactions", "users"
  add_foreign_key "posts", "users"
  add_foreign_key "section_cards", "landing_sections"
  add_foreign_key "sessions", "users"

  # Virtual tables defined in this database.
  # Note that virtual tables may not work with other database engines. Be careful if changing database.
