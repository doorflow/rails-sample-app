# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::MembersController, type: :controller do
  fixtures :crm_members

  let(:alice) { crm_members(:alice) }
  let(:bob) { crm_members(:bob) }

  describe "POST #sync" do
    before do
      stub_doorflow_connected
      stub_doorflow_person_list([])
      stub_doorflow_person_create({ id: 999, email: bob.email })
      stub_doorflow_person_retrieve({ id: alice.doorflow_person_id, first_name: "Alice" })
    end

    it "syncs members and redirects with a summary notice" do
      post :sync, format: :html
      expect(response).to redirect_to(settings_path)
      expect(flash[:notice]).to match(/\ASync completed — \d+ created/)
      expect(session[:sync_results]).to be_nil
    end

    it "returns JSON results when requested" do
      post :sync, format: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to include("created", "updated", "matched", "failed")
    end

    context "with specific member_ids" do
      it "syncs only specified members" do
        expect_any_instance_of(MemberSyncService).to receive(:sync) do |_, members, **_opts|
          expect(members.pluck(:id)).to eq([ bob.id ])
          { created: [], updated: [], matched: [], failed: [] }
        end

        post :sync, params: { member_ids: [ bob.id ] }, format: :json
      end
    end

    context "with dry_run" do
      it "passes dry_run option to service" do
        expect_any_instance_of(MemberSyncService).to receive(:sync) do |_, _members, **opts|
          expect(opts[:dry_run]).to be true
          { created: [], updated: [], matched: [], failed: [] }
        end

        post :sync, params: { dry_run: "true" }, format: :json
      end
    end

    context "when sync fails" do
      before do
        stub_doorflow_connected
        allow_any_instance_of(MemberSyncService).to receive(:sync).and_raise(StandardError.new("Sync error"))
      end

      it "returns error in JSON" do
        post :sync, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end

      it "redirects with alert in HTML" do
        post :sync, format: :html
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when not connected" do
      before do
        stub_doorflow_configured_but_not_connected
      end

      it "returns unauthorized in JSON" do
        post :sync, format: :json
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Not connected")
      end

      it "redirects with alert in HTML" do
        post :sync, format: :html
        expect(response).to redirect_to(settings_path)
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "POST #link" do
    it "links a member to a DoorFlow person" do
      post :link, params: { id: bob.id, doorflow_person_id: 12345 }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(bob.reload.doorflow_person_id).to eq(12345)
    end

    context "when member not found" do
      it "returns error" do
        post :link, params: { id: 99999, doorflow_person_id: 12345 }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE #unlink" do
    it "unlinks a member from DoorFlow" do
      delete :unlink, params: { id: alice.id }
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
      expect(alice.reload.doorflow_person_id).to be_nil
    end
  end
end
