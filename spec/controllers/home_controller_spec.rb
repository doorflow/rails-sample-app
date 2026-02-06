# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :controller do
  fixtures :crm_members, :crm_teams

  describe "GET #index" do
    context "when DoorFlow is not configured" do
      before { stub_doorflow_not_configured }

      it "renders the index page" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "assigns connection status as not_configured" do
        get :index
        expect(assigns(:connection_status)[:state]).to eq(:not_configured)
      end

      it "assigns member counts" do
        get :index
        expect(assigns(:members_count)).to eq(CrmMember.count)
        expect(assigns(:linked_count)).to eq(CrmMember.linked.count)
        expect(assigns(:teams_count)).to eq(CrmTeam.count)
      end
    end

    context "when DoorFlow is configured but not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "renders the index page" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "assigns connection status as not_connected" do
        get :index
        expect(assigns(:connection_status)[:state]).to eq(:not_connected)
      end
    end

    context "when DoorFlow is connected" do
      before { stub_doorflow_connected }

      it "renders the index page" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "assigns connection status as connected" do
        get :index
        expect(assigns(:connection_status)[:state]).to eq(:connected)
      end
    end
  end
end
