# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamsController, type: :controller do
  fixtures :crm_members, :crm_teams

  let(:engineering) { crm_teams(:engineering) }
  let(:sales) { crm_teams(:sales) }

  describe "GET #index" do
    context "when DoorFlow is connected" do
      before do
        stub_doorflow_connected
        stub_doorflow_group_list([
          { id: 100, name: "Engineering Group" },
          { id: 200, name: "Marketing Group" }
        ])
      end

      it "renders the index page" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "assigns all teams" do
        get :index
        expect(assigns(:teams)).to include(engineering, sales)
      end

      it "fetches groups from DoorFlow" do
        get :index
        expect(assigns(:groups)).to be_an(Array)
        expect(assigns(:groups).first[:name]).to eq("Engineering Group")
      end
    end

    context "when DoorFlow is not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "renders the index page without DoorFlow groups" do
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:groups)).to eq([])
      end
    end
  end

  describe "GET #show" do
    before do
      stub_doorflow_connected
      stub_doorflow_group_list([{ id: 100, name: "Engineering Group" }])
    end

    it "renders the show page" do
      get :show, params: { id: engineering.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:show)
    end

    it "assigns the team" do
      get :show, params: { id: engineering.id }
      expect(assigns(:team)).to eq(engineering)
    end
  end

  describe "GET #new" do
    before do
      stub_doorflow_connected
      stub_doorflow_group_list([{ id: 100, name: "Engineering Group" }])
    end

    it "renders the new page" do
      get :new
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end

    it "assigns a new team" do
      get :new
      expect(assigns(:team)).to be_a_new(CrmTeam)
    end

    it "fetches groups for dropdown" do
      get :new
      expect(assigns(:groups)).to be_an(Array)
    end
  end

  describe "POST #create" do
    before { stub_doorflow_configured_but_not_connected }

    let(:valid_params) do
      { crm_team: { name: "New Team", description: "A new team" } }
    end

    it "creates a new team" do
      expect {
        post :create, params: valid_params
      }.to change(CrmTeam, :count).by(1)
    end

    it "redirects to the teams index" do
      post :create, params: valid_params
      expect(response).to redirect_to(teams_path)
    end

    context "with invalid params" do
      let(:invalid_params) do
        { crm_team: { name: "" } }
      end

      it "does not create a team" do
        expect {
          post :create, params: invalid_params
        }.not_to change(CrmTeam, :count)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    before do
      stub_doorflow_connected
      stub_doorflow_group_list([{ id: 100, name: "Engineering Group" }])
    end

    it "renders the edit page" do
      get :edit, params: { id: engineering.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "assigns the team" do
      get :edit, params: { id: engineering.id }
      expect(assigns(:team)).to eq(engineering)
    end
  end

  describe "PATCH #update" do
    before { stub_doorflow_configured_but_not_connected }

    it "updates the team" do
      patch :update, params: { id: engineering.id, crm_team: { name: "Engineering Updated" } }
      expect(engineering.reload.name).to eq("Engineering Updated")
    end

    it "redirects to the teams index" do
      patch :update, params: { id: engineering.id, crm_team: { name: "Engineering Updated" } }
      expect(response).to redirect_to(teams_path)
    end

    context "when group mapping changes" do
      before do
        stub_doorflow_connected
      end

      it "enqueues a team sync job" do
        expect(SyncTeamMembersJob).to receive(:perform_later).with(engineering.id)

        patch :update, params: { id: engineering.id, crm_team: { doorflow_group_id: 300 } }
      end
    end

    context "when group mapping does not change" do
      before do
        stub_doorflow_connected
        engineering.update!(doorflow_group_id: 100)
      end

      it "does not enqueue a team sync job" do
        expect(SyncTeamMembersJob).not_to receive(:perform_later)

        patch :update, params: { id: engineering.id, crm_team: { name: "Engineering Updated" } }
      end
    end
  end

  describe "DELETE #destroy" do
    it "deletes the team" do
      expect {
        delete :destroy, params: { id: sales.id }
      }.to change(CrmTeam, :count).by(-1)
    end

    it "redirects to the teams index" do
      delete :destroy, params: { id: sales.id }
      expect(response).to redirect_to(teams_path)
    end
  end
end
