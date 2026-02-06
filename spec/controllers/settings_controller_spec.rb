# frozen_string_literal: true

require "rails_helper"

RSpec.describe SettingsController, type: :controller do
  fixtures :crm_members, :crm_teams

  describe "GET #show" do
    context "when DoorFlow is connected" do
      before do
        stub_doorflow_connected
        stub_doorflow_group_list([
          { id: 100, name: "Engineering Group" },
          { id: 200, name: "Marketing Group" }
        ])
        stub_doorflow_credential_type_list([
          { id: 1, name: "Card", technology: "proximity" },
          { id: 2, name: "PIN", technology: "pin" }
        ])
      end

      it "renders the show page" do
        get :show
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end

      it "assigns connection status as connected" do
        get :show
        expect(assigns(:connection_status)[:state]).to eq(:connected)
      end

      it "fetches groups from DoorFlow" do
        get :show
        expect(assigns(:groups)).to be_an(Array)
        expect(assigns(:groups).size).to eq(2)
      end

      it "fetches credential types from DoorFlow" do
        get :show
        expect(assigns(:credential_types)).to be_an(Array)
        expect(assigns(:credential_types).size).to eq(2)
      end

      it "computes member statistics" do
        get :show
        stats = assigns(:member_stats)
        expect(stats[:total]).to eq(CrmMember.count)
        expect(stats[:linked]).to eq(CrmMember.linked.count)
        expect(stats[:unlinked]).to eq(CrmMember.unlinked.count)
      end
    end

    context "when DoorFlow is not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "renders the show page" do
        get :show
        expect(response).to have_http_status(:success)
      end

      it "returns empty arrays for DoorFlow data" do
        get :show
        expect(assigns(:groups)).to eq([])
        expect(assigns(:credential_types)).to eq([])
      end
    end
  end

  describe "POST #refresh" do
    before { stub_doorflow_configured_but_not_connected }

    it "clears cached DoorFlow data" do
      expect(Rails.cache).to receive(:delete).with("doorflow_groups")
      expect(Rails.cache).to receive(:delete).with("doorflow_credential_types")

      post :refresh
    end

    it "redirects to settings page" do
      post :refresh
      expect(response).to redirect_to(settings_path)
    end
  end
end
