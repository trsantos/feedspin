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

ActiveRecord::Schema[7.2].define(version: 2024_11_14_041647) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "entries", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "pub_date", precision: nil
    t.string "url"
    t.integer "feed_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "image"
    t.string "fj_entry_id"
    t.index ["feed_id"], name: "index_entries_on_feed_id"
    t.index ["fj_entry_id", "url"], name: "index_entries_on_fj_entry_id_and_url"
    t.index ["title"], name: "index_entries_on_title"
  end

  create_table "feeds", force: :cascade do |t|
    t.string "title"
    t.string "feed_url"
    t.string "site_url"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.string "logo"
    t.text "description"
    t.boolean "has_only_images"
    t.boolean "fetching", default: true
    t.boolean "top_site"
    t.index ["feed_url"], name: "index_feeds_on_feed_url", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.string "paymentId"
    t.string "token"
    t.string "PayerID"
    t.boolean "executed"
    t.integer "user_id"
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["PayerID"], name: "index_payments_on_PayerID"
    t.index ["paymentId"], name: "index_payments_on_paymentId"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer "user_id"
    t.integer "feed_id"
    t.string "title"
    t.string "site_url"
    t.datetime "visited_at", precision: nil
    t.boolean "starred", default: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.boolean "updated", default: true
    t.datetime "snoozed_at"
    t.index ["feed_id"], name: "index_subscriptions_on_feed_id"
    t.index ["updated"], name: "index_subscriptions_on_updated"
    t.index ["user_id", "feed_id"], name: "index_subscriptions_on_user_id_and_feed_id", unique: true
    t.index ["user_id"], name: "index_subscriptions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "password_digest"
    t.datetime "expiration_date", precision: nil, null: false
    t.string "auth_token"
    t.string "password_reset_token"
    t.datetime "password_reset_sent_at", precision: nil
    t.string "stripe_customer_id"
    t.string "stripe_subscription_status"
    t.boolean "cancel_at_period_end", default: false, null: false
    t.index ["auth_token"], name: "index_users_on_auth_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "payments", "users"
end
