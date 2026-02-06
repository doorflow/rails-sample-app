# frozen_string_literal: true

require "rails_helper"

RSpec.describe MembersController, type: :controller do
  fixtures :crm_members, :crm_teams

  let(:alice) { crm_members(:alice) }
  let(:bob) { crm_members(:bob) }

  describe "GET #index" do
    context "when DoorFlow is not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "renders the index page" do
        get :index
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:index)
      end

      it "assigns all members" do
        get :index
        expect(assigns(:members)).to include(alice, bob)
      end

      it "assigns connected as false" do
        get :index
        expect(assigns(:connected)).to be false
      end
    end

    context "when DoorFlow is connected" do
      before { stub_doorflow_connected }

      it "renders the index page" do
        get :index
        expect(response).to have_http_status(:success)
      end

      it "assigns connected as true" do
        get :index
        expect(assigns(:connected)).to be true
      end
    end
  end

  describe "GET #show" do
    context "when DoorFlow is connected and member is linked" do
      before do
        stub_doorflow_connected
        stub_doorflow_group_list([
          { id: 100, name: "Engineering" },
          { id: 200, name: "Marketing" }
        ])
        stub_doorflow_credential_type_list([
          { id: 1, name: "Card", technology: "proximity" },
          { id: 2, name: "PIN", technology: "pin" }
        ])
        stub_doorflow_person_credentials(alice.doorflow_person_id, [
          { id: 501, credential_type_id: 1, value: "12345678" }
        ])
      end

      it "renders the show page" do
        get :show, params: { id: alice.id }
        expect(response).to have_http_status(:success)
        expect(response).to render_template(:show)
      end

      it "assigns the member" do
        get :show, params: { id: alice.id }
        expect(assigns(:member)).to eq(alice)
      end

      it "fetches credentials from DoorFlow" do
        get :show, params: { id: alice.id }
        expect(assigns(:credentials)).to be_an(Array)
      end

      it "fetches groups from DoorFlow" do
        get :show, params: { id: alice.id }
        expect(assigns(:groups)).to be_an(Array)
        expect(assigns(:groups).first[:name]).to eq("Engineering")
      end

      it "fetches credential types from DoorFlow" do
        get :show, params: { id: alice.id }
        expect(assigns(:credential_types)).to be_an(Array)
      end
    end

    context "when DoorFlow is not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "renders the show page without DoorFlow data" do
        get :show, params: { id: alice.id }
        expect(response).to have_http_status(:success)
        expect(assigns(:credentials)).to eq([])
        expect(assigns(:groups)).to eq([])
      end
    end
  end

  describe "GET #new" do
    before { stub_doorflow_configured_but_not_connected }

    it "renders the new page" do
      get :new
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:new)
    end

    it "assigns a new member" do
      get :new
      expect(assigns(:member)).to be_a_new(CrmMember)
    end
  end

  describe "POST #create" do
    before { stub_doorflow_configured_but_not_connected }

    let(:valid_params) do
      {
        crm_member: {
          first_name: "New",
          last_name: "Member",
          email: "new@example.com",
          membership_type: "standard"
        }
      }
    end

    it "creates a new member" do
      expect {
        post :create, params: valid_params
      }.to change(CrmMember, :count).by(1)
    end

    it "redirects to the member show page" do
      post :create, params: valid_params
      expect(response).to redirect_to(member_path(CrmMember.last))
    end

    context "with invalid params" do
      let(:invalid_params) do
        { crm_member: { first_name: "", last_name: "", email: "" } }
      end

      it "does not create a member" do
        expect {
          post :create, params: invalid_params
        }.not_to change(CrmMember, :count)
      end

      it "renders the new template" do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET #edit" do
    before { stub_doorflow_configured_but_not_connected }

    it "renders the edit page" do
      get :edit, params: { id: alice.id }
      expect(response).to have_http_status(:success)
      expect(response).to render_template(:edit)
    end

    it "assigns the member" do
      get :edit, params: { id: alice.id }
      expect(assigns(:member)).to eq(alice)
    end
  end

  describe "PATCH #update" do
    context "when member is linked and DoorFlow is connected" do
      before do
        stub_doorflow_connected
      end

      it "updates the member" do
        patch :update, params: { id: alice.id, crm_member: { first_name: "Alice Updated" } }
        expect(alice.reload.first_name).to eq("Alice Updated")
      end

      it "enqueues a sync job" do
        expect(SyncMemberJob).to receive(:perform_later).with(alice.id)

        patch :update, params: { id: alice.id, crm_member: { first_name: "Alice Updated" } }
      end

      it "redirects to the member show page" do
        patch :update, params: { id: alice.id, crm_member: { first_name: "Alice Updated" } }
        expect(response).to redirect_to(member_path(alice))
      end
    end

    context "when member is not linked" do
      before { stub_doorflow_connected }

      it "updates the member without enqueuing sync" do
        expect(SyncMemberJob).not_to receive(:perform_later)

        patch :update, params: { id: bob.id, crm_member: { first_name: "Bob Updated" } }
        expect(bob.reload.first_name).to eq("Bob Updated")
      end
    end
  end

  describe "DELETE #destroy" do
    context "when member is linked and DoorFlow is connected" do
      before do
        stub_doorflow_connected
      end

      it "deletes the member" do
        expect {
          delete :destroy, params: { id: alice.id }
        }.to change(CrmMember, :count).by(-1)
      end

      it "enqueues a delete job" do
        expect(DeletePersonJob).to receive(:perform_later).with(alice.doorflow_person_id, member_email: alice.email)

        delete :destroy, params: { id: alice.id }
      end

      it "redirects to the members index" do
        delete :destroy, params: { id: alice.id }
        expect(response).to redirect_to(members_path)
      end
    end

    context "when member is not linked" do
      before { stub_doorflow_connected }

      it "deletes the member without enqueuing delete job" do
        expect(DeletePersonJob).not_to receive(:perform_later)

        expect {
          delete :destroy, params: { id: bob.id }
        }.to change(CrmMember, :count).by(-1)
      end
    end
  end
end
