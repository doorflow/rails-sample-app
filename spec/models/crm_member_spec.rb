# frozen_string_literal: true

require "rails_helper"

RSpec.describe CrmMember, type: :model do
  fixtures :crm_members, :crm_teams

  let(:alice) { crm_members(:alice) }
  let(:bob) { crm_members(:bob) }
  let(:engineering) { crm_teams(:engineering) }
  let(:sales) { crm_teams(:sales) }

  describe "validations" do
    it "is valid with valid attributes" do
      member = CrmMember.new(
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        membership_type: "standard"
      )
      expect(member).to be_valid
    end

    it "requires first_name" do
      member = CrmMember.new(first_name: nil, last_name: "User", email: "test@example.com")
      expect(member).not_to be_valid
      expect(member.errors[:first_name]).to include("can't be blank")
    end

    it "requires last_name" do
      member = CrmMember.new(first_name: "Test", last_name: nil, email: "test@example.com")
      expect(member).not_to be_valid
      expect(member.errors[:last_name]).to include("can't be blank")
    end

    it "requires email" do
      member = CrmMember.new(first_name: "Test", last_name: "User", email: nil)
      expect(member).not_to be_valid
      expect(member.errors[:email]).to include("can't be blank")
    end

    it "requires valid email format" do
      member = CrmMember.new(first_name: "Test", last_name: "User", email: "invalid")
      expect(member).not_to be_valid
      expect(member.errors[:email]).to include("is invalid")
    end

    it "requires unique email" do
      member = CrmMember.new(
        first_name: "Test",
        last_name: "User",
        email: alice.email,
        membership_type: "standard"
      )
      expect(member).not_to be_valid
      expect(member.errors[:email]).to include("has already been taken")
    end

    it "validates membership_type inclusion" do
      member = CrmMember.new(
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        membership_type: "invalid"
      )
      expect(member).not_to be_valid
      expect(member.errors[:membership_type]).to include("is not included in the list")
    end

    it "accepts standard membership_type" do
      member = CrmMember.new(
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        membership_type: "standard"
      )
      expect(member).to be_valid
    end

    it "accepts premium membership_type" do
      member = CrmMember.new(
        first_name: "Test",
        last_name: "User",
        email: "test@example.com",
        membership_type: "premium"
      )
      expect(member).to be_valid
    end
  end

  describe "scopes" do
    describe ".linked" do
      it "returns members with doorflow_person_id" do
        expect(CrmMember.linked).to include(alice)
        expect(CrmMember.linked).not_to include(bob)
      end
    end

    describe ".unlinked" do
      it "returns members without doorflow_person_id" do
        expect(CrmMember.unlinked).to include(bob)
        expect(CrmMember.unlinked).not_to include(alice)
      end
    end

    describe ".premium" do
      it "returns premium members" do
        alice.update!(membership_type: "premium")
        bob.update!(membership_type: "standard")

        expect(CrmMember.premium).to include(alice)
        expect(CrmMember.premium).not_to include(bob)
      end
    end

    describe ".standard" do
      it "returns standard members" do
        alice.update!(membership_type: "standard")
        bob.update!(membership_type: "premium")

        expect(CrmMember.standard).to include(alice)
        expect(CrmMember.standard).not_to include(bob)
      end
    end
  end

  describe "#linked?" do
    it "returns true when doorflow_person_id is present" do
      expect(alice.linked?).to be true
    end

    it "returns false when doorflow_person_id is nil" do
      expect(bob.linked?).to be false
    end
  end

  describe "#full_name" do
    it "returns first and last name" do
      expect(alice.full_name).to eq("#{alice.first_name} #{alice.last_name}")
    end
  end

  describe "#initials" do
    it "returns uppercase initials" do
      alice.first_name = "alice"
      alice.last_name = "smith"
      expect(alice.initials).to eq("AS")
    end
  end

  describe "#premium?" do
    it "returns true for premium members" do
      alice.membership_type = "premium"
      expect(alice.premium?).to be true
    end

    it "returns false for standard members" do
      alice.membership_type = "standard"
      expect(alice.premium?).to be false
    end
  end

  describe "#doorflow_group_ids" do
    before do
      engineering.update!(doorflow_group_id: 100)
      sales.update!(doorflow_group_id: 200)
    end

    it "returns group IDs from teams with doorflow mappings" do
      alice.crm_teams = [engineering, sales]

      expect(alice.doorflow_group_ids).to contain_exactly(100, 200)
    end

    it "excludes teams without doorflow mappings" do
      engineering.update!(doorflow_group_id: nil)
      alice.crm_teams = [engineering, sales]

      expect(alice.doorflow_group_ids).to eq([200])
    end

    it "returns empty array when member has no teams" do
      alice.crm_teams = []
      expect(alice.doorflow_group_ids).to eq([])
    end
  end

  describe "#to_doorflow_params" do
    before do
      engineering.update!(doorflow_group_id: 100)
      alice.crm_teams = [engineering]
    end

    it "returns hash with member attributes" do
      params = alice.to_doorflow_params

      expect(params[:first_name]).to eq(alice.first_name)
      expect(params[:last_name]).to eq(alice.last_name)
      expect(params[:email]).to eq(alice.email)
      expect(params[:system_id]).to eq(alice.id.to_s)
      expect(params[:group_ids]).to eq([100])
    end

    it "maps phone to telephone" do
      alice.phone = "555-1234"
      params = alice.to_doorflow_params

      expect(params[:telephone]).to eq("555-1234")
    end

    it "maps membership_type to custom_1" do
      alice.membership_type = "premium"
      params = alice.to_doorflow_params

      expect(params[:custom_1]).to eq("premium")
    end

    it "excludes nil values" do
      alice.phone = nil
      alice.mobile = nil
      params = alice.to_doorflow_params

      expect(params).not_to have_key(:telephone)
      expect(params).not_to have_key(:mobile)
    end

    it "excludes image by default" do
      alice.image = "photo.jpg"
      params = alice.to_doorflow_params

      expect(params).not_to have_key(:image_file)
    end

    it "includes image when include_image is true and image exists" do
      alice.image = "photo.jpg"
      # Create a fake image file
      FileUtils.mkdir_p(Rails.root.join("public", "images", "members"))
      File.write(alice.image_path, "fake image data")

      params = alice.to_doorflow_params(include_image: true)

      expect(params[:image_file]).to eq(alice.image_path.to_s)

      # Cleanup
      File.delete(alice.image_path) if File.exist?(alice.image_path)
    end
  end

  describe "#image_url" do
    it "returns nil when image is not present" do
      alice.image = nil
      expect(alice.image_url).to be_nil
    end

    it "returns URL path when image is present" do
      alice.image = "photo.jpg"
      expect(alice.image_url).to eq("/images/members/photo.jpg")
    end
  end
end
