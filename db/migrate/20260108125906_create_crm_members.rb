class CreateCrmMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :crm_members do |t|
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :department
      t.string :job_title
      t.text :notes
      t.string :membership_type, default: "standard"
      t.integer :doorflow_person_id

      t.timestamps
    end

    add_index :crm_members, :email, unique: true
    add_index :crm_members, :doorflow_person_id
  end
end
