class AddMobileToCrmMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :crm_members, :mobile, :string
  end
end
