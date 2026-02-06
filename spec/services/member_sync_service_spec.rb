# frozen_string_literal: true

require "rails_helper"

RSpec.describe MemberSyncService do
  fixtures :crm_members, :crm_teams

  let(:alice) { crm_members(:alice) }
  let(:bob) { crm_members(:bob) }

  before { stub_doorflow_connected }

  # Helper to create a service with the stubbed client
  def create_service
    described_class.new(client: @client_double)
  end

  describe "#sync" do
    context "when syncing linked members" do
      before do
        stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
      end

      it "updates existing people in DoorFlow" do
        person = stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
        expect(person).to receive(:update)

        results = create_service.sync(CrmMember.where(id: alice.id))
        expect(results[:updated].size).to eq(1)
        expect(results[:updated].first[:id]).to eq(alice.id)
      end

      it "does not update in dry_run mode" do
        person = stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
        expect(person).not_to receive(:update)

        results = create_service.sync(CrmMember.where(id: alice.id), dry_run: true)
        expect(results[:updated].size).to eq(1)
      end
    end

    context "when syncing unlinked members that exist in DoorFlow" do
      let(:person_resources) do
        stub_doorflow_person_list([{ id: 999, email: bob.email, first_name: "Bob" }])
      end

      before do
        # Bob is unlinked, but exists in DoorFlow by email
        person_resources
      end

      it "links and updates the member" do
        person = person_resources.first
        expect(person).to receive(:update)

        results = create_service.sync(CrmMember.where(id: bob.id))

        expect(results[:matched].size).to eq(1)
        expect(results[:matched].first[:doorflow_person_id]).to eq(999)
        expect(bob.reload.doorflow_person_id).to eq(999)
      end

      it "does not link in dry_run mode" do
        results = create_service.sync(CrmMember.where(id: bob.id), dry_run: true)

        expect(results[:matched].size).to eq(1)
        expect(bob.reload.doorflow_person_id).to be_nil
      end
    end

    context "when syncing unlinked members that don't exist in DoorFlow" do
      before do
        stub_doorflow_person_list([]) # No match by email
        stub_doorflow_person_create({ id: 888, email: bob.email, first_name: "Bob" })
      end

      it "creates a new person in DoorFlow and links" do
        expect(@people_proxy).to receive(:create).and_return(mock_resource(id: 888, email: bob.email))

        results = create_service.sync(CrmMember.where(id: bob.id))

        expect(results[:created].size).to eq(1)
        expect(results[:created].first[:doorflow_person_id]).to eq(888)
        expect(bob.reload.doorflow_person_id).to eq(888)
      end

      it "does not create in dry_run mode" do
        expect(@people_proxy).not_to receive(:create)

        results = create_service.sync(CrmMember.where(id: bob.id), dry_run: true)

        expect(results[:created].size).to eq(1)
        expect(results[:created].first[:doorflow_person_id]).to be_nil
        expect(bob.reload.doorflow_person_id).to be_nil
      end
    end

    context "when sync fails for a member" do
      before do
        stub_doorflow_person_list([])
        allow(@people_proxy).to receive(:create).and_raise(StandardError.new("API Error"))
      end

      it "records the failure and continues" do
        results = create_service.sync(CrmMember.where(id: bob.id))

        expect(results[:failed].size).to eq(1)
        expect(results[:failed].first[:error]).to include("API Error")
      end
    end
  end

  describe "#sync_single" do
    before do
      stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
    end

    it "syncs a single member" do
      person = stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
      expect(person).to receive(:update)

      results = create_service.sync_single(alice)
      expect(results[:updated].size).to eq(1)
    end
  end
end
