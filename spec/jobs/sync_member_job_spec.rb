# frozen_string_literal: true

require "rails_helper"

RSpec.describe SyncMemberJob, type: :job do
  fixtures :crm_members

  let(:alice) { crm_members(:alice) }
  let(:bob) { crm_members(:bob) }

  describe "#perform" do
    context "when DoorFlow is connected" do
      before do
        stub_doorflow_connected
        stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
      end

      it "syncs the member to DoorFlow" do
        person = stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
        expect(person).to receive(:update)

        described_class.perform_now(alice.id)
      end

      it "skips unlinked members" do
        expect_any_instance_of(DoorflowPersonService).not_to receive(:sync_member)

        described_class.perform_now(bob.id)
      end
    end

    context "when member does not exist" do
      before { stub_doorflow_connected }

      it "discards the job" do
        expect { described_class.perform_now(99999) }.not_to raise_error
      end
    end
  end

  describe "job configuration" do
    it "is queued in the default queue" do
      expect(described_class.new.queue_name).to eq("default")
    end
  end
end
