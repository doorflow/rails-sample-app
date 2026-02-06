# frozen_string_literal: true

require "rails_helper"

RSpec.describe DoorflowPersonService do
  fixtures :crm_members, :crm_teams

  let(:alice) { crm_members(:alice) }
  let(:bob) { crm_members(:bob) }

  describe "when connected" do
    before { stub_doorflow_connected }

    let(:service) { described_class.new(client: @client_double) }

    describe "#connected?" do
      it "returns true when client is authenticated" do
        expect(service.connected?).to be true
      end
    end

    describe "#fetch_credentials" do
      before do
        stub_doorflow_person_credentials(alice.doorflow_person_id, [
          { id: 501, credential_type_id: 1, value: "12345678" }
        ])
      end

      it "returns credentials for a person" do
        credentials = service.fetch_credentials(alice.doorflow_person_id)
        expect(credentials).to be_an(Array)
        expect(credentials.first[:id]).to eq(501)
      end

      it "returns empty array for nil person_id" do
        expect(service.fetch_credentials(nil)).to eq([])
      end
    end

    describe "#fetch_groups" do
      before do
        stub_doorflow_group_list([
          { id: 100, name: "Engineering" },
          { id: 200, name: "Marketing" }
        ])
      end

      it "returns groups from DoorFlow" do
        groups = service.fetch_groups
        expect(groups).to be_an(Array)
        expect(groups.size).to eq(2)
        expect(groups.first[:name]).to eq("Engineering")
      end
    end

    describe "#fetch_credential_types" do
      before do
        stub_doorflow_credential_type_list([
          { id: 1, name: "Card", technology: "proximity" },
          { id: 2, name: "PIN", technology: "pin" }
        ])
      end

      it "returns credential types from DoorFlow" do
        types = service.fetch_credential_types
        expect(types).to be_an(Array)
        expect(types.size).to eq(2)
      end
    end

    describe "#sync_member" do
      before do
        stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
      end

      it "syncs a linked member to DoorFlow" do
        person = stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
        expect(person).to receive(:update)

        expect(service.sync_member(alice)).to be true
      end

      it "raises ArgumentError for unlinked members" do
        expect { service.sync_member(bob) }.to raise_error(ArgumentError, /not linked/)
      end

      context "when sync fails" do
        before do
          person = stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
          allow(person).to receive(:update).and_raise(StandardError.new("API Error"))
        end

        it "raises SyncError" do
          expect { service.sync_member(alice) }.to raise_error(DoorflowPersonService::SyncError)
        end
      end
    end

    describe "#update_person_groups" do
      before do
        stub_doorflow_person_retrieve({ id: 123, first_name: "Test" })
      end

      it "updates person groups" do
        person = stub_doorflow_person_retrieve({ id: 123, first_name: "Test" })
        expect(person).to receive(:update).with({ group_ids: [100, 200] })

        expect(service.update_person_groups(123, [100, 200])).to be true
      end
    end

    describe "#delete_person" do
      before do
        stub_doorflow_person_delete(alice.doorflow_person_id)
      end

      it "deletes a person from DoorFlow" do
        expect(@people_proxy).to receive(:delete).with(alice.doorflow_person_id)
        expect(service.delete_person(alice.doorflow_person_id)).to be true
      end

      context "when delete fails" do
        before do
          allow(@people_proxy).to receive(:delete).and_raise(StandardError.new("API Error"))
        end

        it "raises DeleteError" do
          expect { service.delete_person(alice.doorflow_person_id) }.to raise_error(DoorflowPersonService::DeleteError)
        end
      end
    end

    describe "#create_credential" do
      before do
        stub_doorflow_credential_create({
          id: 601,
          person_id: 123,
          credential_type_id: 1,
          value: "87654321"
        })
      end

      it "creates a credential" do
        result = service.create_credential(
          person_id: 123,
          credential_type_id: 1,
          value: "87654321"
        )
        expect(result[:id]).to eq(601)
      end
    end

    describe "#delete_credential" do
      it "deletes a credential" do
        expect(@credentials_proxy).to receive(:delete).with(501)
        expect(service.delete_credential(501)).to be true
      end
    end
  end

  describe "when not connected" do
    before { stub_doorflow_configured_but_not_connected }

    let(:service) { described_class.new(client: nil) }

    describe "#connected?" do
      it "returns false" do
        expect(service.connected?).to be false
      end
    end

    describe "#fetch_credentials" do
      it "returns empty array" do
        expect(service.fetch_credentials(123)).to eq([])
      end
    end

    describe "#fetch_groups" do
      it "returns empty array" do
        expect(service.fetch_groups).to eq([])
      end
    end

    describe "#sync_member" do
      it "raises NotConnectedError" do
        expect { service.sync_member(alice) }.to raise_error(DoorflowPersonService::NotConnectedError)
      end
    end

    describe "#delete_person" do
      it "raises NotConnectedError" do
        expect { service.delete_person(123) }.to raise_error(DoorflowPersonService::NotConnectedError)
      end
    end
  end
end
