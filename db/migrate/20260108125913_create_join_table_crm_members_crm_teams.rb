class CreateJoinTableCrmMembersCrmTeams < ActiveRecord::Migration[8.0]
  def change
    create_join_table :crm_members, :crm_teams do |t|
      t.index [:crm_member_id, :crm_team_id], unique: true
      t.index [:crm_team_id, :crm_member_id]
    end
  end
end
