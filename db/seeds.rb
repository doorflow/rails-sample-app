# frozen_string_literal: true

# Sample data for the DoorFlow example application
# This matches the TypeScript example for consistency across implementations

puts "Creating teams..."

teams = {
  engineering: CrmTeam.find_or_create_by!(name: "Engineering") do |team|
    team.description = "Software development team"
  end,
  sales: CrmTeam.find_or_create_by!(name: "Sales") do |team|
    team.description = "Sales and business development"
  end,
  operations: CrmTeam.find_or_create_by!(name: "Operations") do |team|
    team.description = "Operations and support"
  end
}

puts "Created #{CrmTeam.count} teams"

puts "Creating members..."

members_data = [
  {
    first_name: "Alice",
    last_name: "Smith",
    email: "alice.smith@example.com",
    phone: "+1-555-0101",
    mobile: "+1-555-1001",
    department: "Engineering",
    job_title: "Senior Developer",
    notes: "Team lead for the mobile app project",
    membership_type: "premium",
    image: "alice_smith.png",
    teams: [:engineering]
  },
  {
    first_name: "Bob",
    last_name: "Johnson",
    email: "bob.johnson@example.com",
    phone: "+1-555-0102",
    mobile: "+1-555-1002",
    department: "Sales",
    job_title: "Account Executive",
    notes: nil,
    membership_type: "standard",
    image: "bob_johnson.png",
    teams: [:sales]
  },
  {
    first_name: "Carol",
    last_name: "Williams",
    email: "carol.williams@example.com",
    phone: "+1-555-0103",
    mobile: "+1-555-1003",
    department: "Engineering",
    job_title: "DevOps Engineer",
    notes: "On-call rotation lead",
    membership_type: "premium",
    image: "carol_williams.png",
    teams: [:engineering, :operations]
  },
  {
    first_name: "Eva",
    last_name: "Martinez",
    email: "eva.martinez@example.com",
    phone: nil,
    mobile: "+1-555-1004",
    department: "Operations",
    job_title: "Office Manager",
    notes: nil,
    membership_type: "standard",
    image: "eva_martinez.png",
    teams: []
  }
]

members_data.each do |member_attrs|
  team_keys = member_attrs.delete(:teams)

  member = CrmMember.find_or_create_by!(email: member_attrs[:email]) do |m|
    m.assign_attributes(member_attrs)
  end

  # Assign teams
  member.crm_teams = team_keys.map { |key| teams[key] }
end

puts "Created #{CrmMember.count} members"

puts "Seed data loaded successfully!"
puts ""
puts "Summary:"
puts "  - #{CrmTeam.count} teams"
puts "  - #{CrmMember.count} members"
puts "  - #{CrmMember.premium.count} premium members"
puts "  - #{CrmMember.standard.count} standard members"
