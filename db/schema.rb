# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20150903181554) do

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer  "priority",       default: 0, null: false
    t.integer  "attempts",       default: 0, null: false
    t.text     "handler",                    null: false
    t.text     "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string   "locked_by"
    t.string   "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "owner_type"
    t.integer  "owner_id"
    t.string   "owner_job_type"
    t.integer  "user_id"
  end

  add_index "delayed_jobs", ["owner_type", "owner_id"], name: "index_delayed_jobs_on_owner_type_and_owner_id"
  add_index "delayed_jobs", ["priority", "run_at"], name: "delayed_jobs_priority"

  create_table "micropost_recipients", force: :cascade do |t|
    t.integer  "micropost_id"
    t.integer  "recipient_id"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "microposts", force: :cascade do |t|
    t.text     "content"
    t.integer  "user_id"
    t.datetime "created_at",       null: false
    t.datetime "updated_at",       null: false
    t.string   "picture"
    t.integer  "delayed_job_id"
    t.string   "title"
    t.boolean  "check_in_current"
    t.integer  "days_to_complete"
    t.integer  "days_completed"
    t.integer  "days_remaining"
    t.integer  "current_day"
    t.boolean  "active"
  end

  add_index "microposts", ["user_id", "created_at"], name: "index_microposts_on_user_id_and_created_at"
  add_index "microposts", ["user_id"], name: "index_microposts_on_user_id"

  create_table "recipients", force: :cascade do |t|
    t.string   "name"
    t.string   "phone"
    t.integer  "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "relationships", force: :cascade do |t|
    t.integer  "follower_id"
    t.integer  "followed_id"
    t.datetime "created_at",  null: false
    t.datetime "updated_at",  null: false
  end

  add_index "relationships", ["followed_id"], name: "index_relationships_on_followed_id"
  add_index "relationships", ["follower_id", "followed_id"], name: "index_relationships_on_follower_id_and_followed_id", unique: true
  add_index "relationships", ["follower_id"], name: "index_relationships_on_follower_id"

  create_table "users", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
    t.string   "password_digest"
    t.string   "remember_digest"
    t.boolean  "admin",             default: false
    t.string   "activation_digest"
    t.boolean  "activated",         default: false
    t.datetime "activated_at"
    t.string   "reset_digest"
    t.datetime "reset_sent_at"
    t.string   "phone_number"
    t.string   "phone_pin"
    t.boolean  "phone_verified"
    t.text     "current_tasks_map"
    t.string   "last_name"
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true

end
