class AddImageToCrmMembers < ActiveRecord::Migration[8.0]
  def change
    add_column :crm_members, :image, :string
  end
end
