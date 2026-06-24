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

ActiveRecord::Schema[8.1].define(version: 2026_06_01_172820) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "enrollment_reviews", force: :cascade do |t|
    t.integer "apoyo_psicosocial_score"
    t.integer "busqueda_rescate_score"
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "enrollment_id", null: false
    t.integer "logistica_abastecimiento_score"
    t.integer "maquinaria_construccion_score"
    t.integer "primeros_auxilios_score"
    t.bigint "reviewer_id", null: false
    t.datetime "updated_at", null: false
    t.index ["enrollment_id", "reviewer_id"], name: "index_enrollment_reviews_on_enrollment_id_and_reviewer_id", unique: true
    t.index ["enrollment_id"], name: "index_enrollment_reviews_on_enrollment_id"
    t.index ["reviewer_id"], name: "index_enrollment_reviews_on_reviewer_id"
  end

  create_table "enrollments", force: :cascade do |t|
    t.datetime "attended_at"
    t.datetime "check_in_time"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "expected_arrival"
    t.float "score_snapshot"
    t.boolean "second_wave", default: false, null: false
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_enrollments_on_event_id"
    t.index ["user_id"], name: "index_enrollments_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "date"
    t.text "description"
    t.integer "emergency_level"
    t.string "emergency_type"
    t.string "location"
    t.integer "min_score", default: 3
    t.bigint "organization_id", null: false
    t.text "required_skills", default: [], array: true
    t.integer "status", comment: "0=activo 1=finalizado 2=en_curso 3=cancelado"
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_events_on_organization_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id"], name: "index_messages_on_event_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "message", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.boolean "read", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "location"
    t.string "name"
    t.string "ruc"
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_organizations_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "apellidos"
    t.string "cedula"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name"
    t.string "nombres"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 2
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "volunteer_profiles", force: :cascade do |t|
    t.boolean "available", default: true
    t.jsonb "certifications", default: {}
    t.string "city"
    t.string "country"
    t.datetime "created_at", null: false
    t.jsonb "quiz_answers", default: {}
    t.datetime "quiz_completed_at"
    t.decimal "score", precision: 4, scale: 2, default: "0.0"
    t.string "sector"
    t.jsonb "skill_scores", default: {}
    t.text "skills", default: [], array: true
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_volunteer_profiles_on_user_id", unique: true
  end

  add_foreign_key "enrollment_reviews", "enrollments"
  add_foreign_key "enrollment_reviews", "users", column: "reviewer_id"
  add_foreign_key "enrollments", "events"
  add_foreign_key "enrollments", "users"
  add_foreign_key "events", "organizations"
  add_foreign_key "messages", "events"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users"
  add_foreign_key "organizations", "users"
  add_foreign_key "volunteer_profiles", "users"
end
