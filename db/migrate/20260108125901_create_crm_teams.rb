class CreateCrmTeams < ActiveRecord::Migration[8.0]
  def change
    create_table :crm_teams do |t|
      t.string :name, null: false
      t.text :description
      t.integer :doorflow_group_id

      t.timestamps
    end

    add_index :crm_teams, :name
    add_index :crm_teams, :doorflow_group_id
  end
end
