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

ActiveRecord::Schema[8.0].define(version: 2026_02_04_191512) do
  create_table "crm_members", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "department"
    t.string "job_title"
    t.text "notes"
    t.string "membership_type", default: "standard"
    t.integer "doorflow_person_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "image"
    t.string "mobile"
    t.index ["doorflow_person_id"], name: "index_crm_members_on_doorflow_person_id"
    t.index ["email"], name: "index_crm_members_on_email", unique: true
  end

  create_table "crm_members_teams", id: false, force: :cascade do |t|
    t.integer "crm_member_id", null: false
    t.integer "crm_team_id", null: false
    t.index ["crm_member_id", "crm_team_id"], name: "index_crm_members_teams_on_crm_member_id_and_crm_team_id", unique: true
    t.index ["crm_team_id", "crm_member_id"], name: "index_crm_members_teams_on_crm_team_id_and_crm_member_id"
  end

  create_table "crm_teams", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "doorflow_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["doorflow_group_id"], name: "index_crm_teams_on_doorflow_group_id"
    t.index ["name"], name: "index_crm_teams_on_name"
  end
end
