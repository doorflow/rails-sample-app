# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::DoorflowController, type: :controller do
  fixtures :crm_members

  describe "before_action :ensure_connected" do
    context "when not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "returns unauthorized for all actions" do
        get :people
        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Not connected")
      end
    end
  end

  context "when connected to DoorFlow" do
    before { stub_doorflow_connected }

    describe "GET #people" do
      before do
        stub_doorflow_person_list([
          { id: 1, first_name: "John", last_name: "Doe", email: "john@example.com" },
          { id: 2, first_name: "Jane", last_name: "Smith", email: "jane@example.com" }
        ])
      end

      it "returns a list of people" do
        get :people
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
      end

      it "calls the people proxy list method" do
        expect(@people_proxy).to receive(:list)
        get :people
      end
    end

    describe "GET #person" do
      before do
        stub_doorflow_person_retrieve({ id: 123, first_name: "John", last_name: "Doe" })
      end

      it "returns a single person" do
        get :person, params: { id: 123 }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["first_name"]).to eq("John")
      end

      it "calls the people proxy retrieve method" do
        expect(@people_proxy).to receive(:retrieve).with("123")
        get :person, params: { id: 123 }
      end
    end

    describe "GET #groups" do
      before do
        stub_doorflow_group_list([
          { id: 100, name: "Engineering" },
          { id: 200, name: "Marketing" }
        ])
      end

      it "returns a list of groups" do
        get :groups
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
      end

      it "calls the groups proxy list method" do
        expect(@groups_proxy).to receive(:list)
        get :groups
      end
    end

    describe "GET #credentials" do
      before do
        stub_doorflow_credential_list([
          { id: 501, credential_type_id: 1, value: "12345678" },
          { id: 502, credential_type_id: 2, value: "1234" }
        ])
      end

      it "returns a list of credentials" do
        get :credentials
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.size).to eq(2)
      end

      it "calls the credentials proxy list method" do
        expect(@credentials_proxy).to receive(:list)
        get :credentials
      end
    end

    describe "POST #create_credential" do
      before do
        stub_doorflow_credential_create({
          id: 601,
          person_id: 123,
          credential_type_id: 1,
          value: "87654321"
        })
      end

      it "creates a credential and returns it" do
        post :create_credential, params: {
          person_id: 123,
          credential_type_id: 1,
          value: "87654321"
        }
        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["id"]).to eq(601)
      end

      it "calls the credentials proxy create method" do
        expect(@credentials_proxy).to receive(:create).with(
          hash_including(person_id: "123", credential_type_id: "1")
        )
        post :create_credential, params: {
          person_id: 123,
          credential_type_id: 1,
          value: "87654321"
        }
      end

      context "with pin_mode auto" do
        it "uses auto-generate marker for PIN value" do
          expect(@credentials_proxy).to receive(:create).with(
            hash_including(value: "******")
          )
          post :create_credential, params: {
            person_id: 123,
            credential_type_id: 2,
            pin_mode: "auto"
          }
        end
      end
    end

    describe "DELETE #destroy_credential" do
      before do
        stub_doorflow_credential_retrieve({ id: 501, person_id: 123 })
      end

      it "deletes the credential" do
        delete :destroy_credential, params: { person_id: 123, id: 501 }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end

      it "calls the credentials proxy delete method" do
        expect(@credentials_proxy).to receive(:delete).and_return(true)

        delete :destroy_credential, params: { person_id: 123, id: 501 }
      end
    end

    describe "PUT #update_person_groups" do
      before do
        stub_doorflow_person_retrieve({ id: 123, first_name: "John" })
      end

      it "updates person groups" do
        put :update_person_groups, params: { person_id: 123, group_ids: [100, 200] }
        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["group_ids"]).to eq(["100", "200"])
      end

      it "calls person.update with group_ids" do
        person = stub_doorflow_person_retrieve({ id: 123, first_name: "John" })
        expect(person).to receive(:update).with({ group_ids: ["100", "200"] })

        put :update_person_groups, params: { person_id: 123, group_ids: [100, 200] }
      end
    end
  end
end
