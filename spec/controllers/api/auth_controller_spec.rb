# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::AuthController, type: :controller do
  describe "GET #status" do
    context "when DoorFlow is not configured" do
      before { stub_doorflow_not_configured }

      it "returns configured: false" do
        get :status
        json = JSON.parse(response.body)
        expect(json["configured"]).to be false
        expect(json["connected"]).to be false
      end
    end

    context "when DoorFlow is configured but not connected" do
      before { stub_doorflow_configured_but_not_connected }

      it "returns configured: true, connected: false" do
        get :status
        json = JSON.parse(response.body)
        expect(json["configured"]).to be true
        expect(json["connected"]).to be false
      end
    end

    context "when DoorFlow is connected" do
      before { stub_doorflow_connected }

      it "returns configured: true, connected: true" do
        get :status
        json = JSON.parse(response.body)
        expect(json["configured"]).to be true
        expect(json["connected"]).to be true
      end
    end
  end

  describe "GET #connect" do
    before do
      stub_doorflow_env_vars_for_auth

      auth_double = instance_double(DoorFlow::Auth::DoorFlowAuth)
      allow(auth_double).to receive(:authorization_url).and_return([
        "https://doorflow.com/oauth/authorize?client_id=test",
        "random_state",
        "code_verifier"
      ])
      allow(DoorFlow::Auth::DoorFlowAuth).to receive(:new).and_return(auth_double)
    end

    it "redirects to DoorFlow authorization URL" do
      get :connect
      expect(response).to redirect_to(/doorflow\.com\/oauth\/authorize/)
    end

    it "stores OAuth state in session" do
      get :connect
      expect(session[:oauth_state]).to eq("random_state")
      expect(session[:oauth_code_verifier]).to eq("code_verifier")
    end
  end

  describe "GET #callback" do
    before do
      stub_doorflow_env_vars_for_auth
      session[:oauth_state] = "expected_state"
      session[:oauth_code_verifier] = "expected_verifier"
    end

    context "with valid authorization code" do
      before do
        auth_double = instance_double(DoorFlow::Auth::DoorFlowAuth)
        allow(auth_double).to receive(:handle_callback)
        allow(DoorFlow::Auth::DoorFlowAuth).to receive(:new).and_return(auth_double)
      end

      it "handles the callback and redirects to root" do
        get :callback, params: { code: "auth_code", state: "expected_state" }
        expect(response).to redirect_to(root_path)
      end

      it "clears OAuth state from session" do
        get :callback, params: { code: "auth_code", state: "expected_state" }
        expect(session[:oauth_state]).to be_nil
        expect(session[:oauth_code_verifier]).to be_nil
      end
    end

    context "without authorization code" do
      it "redirects with error message" do
        get :callback, params: { state: "expected_state" }
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("no code received")
      end
    end
  end

  describe "DELETE #disconnect" do
    before do
      stub_doorflow_connected

      auth_double = instance_double(DoorFlow::Auth::DoorFlowAuth)
      allow(auth_double).to receive(:authenticated?).and_return(true)
      allow(auth_double).to receive(:disconnect)
      allow(DoorFlow::Auth::DoorFlowAuth).to receive(:new).and_return(auth_double)
    end

    it "disconnects and redirects to root" do
      delete :disconnect
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("Disconnected")
    end
  end

  describe "POST #refresh" do
    before do
      stub_doorflow_connected

      auth_double = instance_double(DoorFlow::Auth::DoorFlowAuth)
      allow(auth_double).to receive(:authenticated?).and_return(true)
      allow(auth_double).to receive(:refresh_access_token)
      allow(DoorFlow::Auth::DoorFlowAuth).to receive(:new).and_return(auth_double)
    end

    it "refreshes token and redirects to root" do
      post :refresh
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to include("refreshed")
    end
  end

  private

  def stub_doorflow_env_vars_for_auth
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DOORFLOW_CLIENT_ID").and_return("test_client_id")
    allow(ENV).to receive(:[]).with("DOORFLOW_CLIENT_SECRET").and_return("test_client_secret")
    allow(ENV).to receive(:[]).with("DOORFLOW_REDIRECT_URI").and_return("http://localhost:3000/callback")
    allow(ENV).to receive(:fetch).with("DOORFLOW_CLIENT_ID").and_return("test_client_id")
    allow(ENV).to receive(:fetch).with("DOORFLOW_CLIENT_SECRET").and_return("test_client_secret")
    allow(ENV).to receive(:fetch).with("DOORFLOW_REDIRECT_URI").and_return("http://localhost:3000/callback")
    allow(ENV).to receive(:fetch).with("DOORFLOW_API_BASE", anything).and_return("https://api.doorflow.com")
    allow(ENV).to receive(:fetch).with("DOORFLOW_SCOPES", anything).and_return("read write")
  end
end
