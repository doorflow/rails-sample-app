# frozen_string_literal: true

require "ostruct"

# Helper module for stubbing DoorFlow SDK calls in tests.
# These stubs work with the client-instance pattern (doorflow.people.list, etc.)
module DoorflowStubHelpers
  # Stub DoorFlow as not configured (missing environment variables)
  def stub_doorflow_not_configured
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with("DOORFLOW_CLIENT_ID").and_return(nil)
    allow(ENV).to receive(:[]).with("DOORFLOW_CLIENT_SECRET").and_return(nil)
    allow(ENV).to receive(:[]).with("DOORFLOW_REDIRECT_URI").and_return(nil)
  end

  # Stub DoorFlow as configured but not connected (no valid tokens)
  def stub_doorflow_configured_but_not_connected
    stub_doorflow_env_vars

    # Stub auth to return not authenticated
    auth_double = instance_double(DoorFlow::Auth::DoorFlowAuth)
    allow(auth_double).to receive(:authenticated?).and_return(false)
    allow(auth_double).to receive(:access_token).and_return(nil)
    allow(DoorFlow::Auth::DoorFlowAuth).to receive(:new).and_return(auth_double)

    # Stub token storage
    storage_double = instance_double(TokenStorageService)
    allow(storage_double).to receive(:load).and_return(nil)
    allow(TokenStorageService).to receive(:new).and_return(storage_double)
  end

  # Stub DoorFlow as fully connected and ready to use
  def stub_doorflow_connected
    stub_doorflow_env_vars

    # Stub auth to return authenticated
    @auth_double = instance_double(DoorFlow::Auth::DoorFlowAuth)
    allow(@auth_double).to receive(:authenticated?).and_return(true)
    allow(@auth_double).to receive(:access_token).and_return("test_access_token")
    allow(@auth_double).to receive(:authorization_url).and_return(["https://auth.doorflow.com/authorize?...", "state123", "verifier123"])
    allow(@auth_double).to receive(:handle_callback).and_return(true)
    allow(@auth_double).to receive(:disconnect).and_return(true)
    allow(@auth_double).to receive(:refresh_access_token).and_return(true)
    allow(DoorFlow::Auth::DoorFlowAuth).to receive(:new).and_return(@auth_double)

    # Stub token storage
    storage_double = instance_double(TokenStorageService)
    allow(storage_double).to receive(:load).and_return(
      OpenStruct.new(expires_at: 1.hour.from_now, scope: "read write")
    )
    allow(TokenStorageService).to receive(:new).and_return(storage_double)

    # Stub the client and its proxy objects
    setup_client_stubs
  end

  # Create a mock resource with attributes and methods
  def mock_resource(data)
    resource = double("Resource")
    allow(resource).to receive(:attributes).and_return(data)
    allow(resource).to receive(:id).and_return(data[:id])
    allow(resource).to receive(:to_hash).and_return(data)
    allow(resource).to receive(:to_h).and_return(data)
    allow(resource).to receive(:update).and_return(resource)
    allow(resource).to receive(:delete).and_return(true)

    # Allow attribute access
    data.each do |key, value|
      allow(resource).to receive(key).and_return(value) if key.is_a?(Symbol)
    end

    resource
  end

  # Stub person-related SDK methods
  # Returns the array of mock resources so tests can set expectations on them
  def stub_doorflow_person_list(people = [])
    resources = people.map { |p| mock_resource(p) }
    list_object = DoorFlow::ListObject.new(
      data: resources,
      total: people.size,
      page: 1,
      per_page: 25,
      resource_class: DoorFlow::Resources::Person
    )
    allow(@people_proxy).to receive(:list).and_return(list_object)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::PersonResource).to receive(:list).and_return(list_object) if defined?(DoorFlow::PersonResource)

    resources
  end

  def stub_doorflow_person_retrieve(person_data)
    person = mock_resource(person_data)
    allow(@people_proxy).to receive(:retrieve).and_return(person)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::PersonResource).to receive(:retrieve).and_return(person) if defined?(DoorFlow::PersonResource)
    person
  end

  def stub_doorflow_person_create(person_data)
    person = mock_resource(person_data)
    allow(@people_proxy).to receive(:create).and_return(person)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::PersonResource).to receive(:create).and_return(person) if defined?(DoorFlow::PersonResource)
    person
  end

  def stub_doorflow_person_delete(person_id)
    allow(@people_proxy).to receive(:delete).with(person_id).and_return(true)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::PersonResource).to receive(:delete).with(person_id).and_return(true) if defined?(DoorFlow::PersonResource)
  end

  # Stub group-related SDK methods
  def stub_doorflow_group_list(groups = [])
    resources = groups.map { |g| mock_resource(g) }
    list_object = DoorFlow::ListObject.new(
      data: resources,
      total: groups.size,
      page: 1,
      per_page: 25,
      resource_class: DoorFlow::Resources::Group
    )
    allow(@groups_proxy).to receive(:list).and_return(list_object)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::GroupResource).to receive(:list).and_return(list_object) if defined?(DoorFlow::GroupResource)
  end

  # Stub credential type-related SDK methods
  def stub_doorflow_credential_type_list(types = [])
    resources = types.map { |t| mock_resource(t) }
    list_object = DoorFlow::ListObject.new(
      data: resources,
      total: types.size,
      page: 1,
      per_page: 25,
      resource_class: DoorFlow::Resources::CredentialType
    )
    allow(@credential_types_proxy).to receive(:list).and_return(list_object)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::CredentialTypeResource).to receive(:list).and_return(list_object) if defined?(DoorFlow::CredentialTypeResource)
  end

  # Stub credential-related SDK methods
  def stub_doorflow_credential_list(credentials = [])
    resources = credentials.map { |c| mock_resource(c) }
    list_object = DoorFlow::ListObject.new(
      data: resources,
      total: credentials.size,
      page: 1,
      per_page: 25,
      resource_class: DoorFlow::Resources::Credential
    )
    allow(@credentials_proxy).to receive(:list).and_return(list_object)
    allow(@credentials_proxy).to receive(:list_for_person).and_return(resources)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::CredentialResource).to receive(:list).and_return(list_object) if defined?(DoorFlow::CredentialResource)
  end

  def stub_doorflow_credential_create(credential_data)
    credential = mock_resource(credential_data)
    allow(@credentials_proxy).to receive(:create).and_return(credential)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::CredentialResource).to receive(:create).and_return(credential) if defined?(DoorFlow::CredentialResource)
    credential
  end

  def stub_doorflow_credential_retrieve(credential_data)
    credential = mock_resource(credential_data)
    allow(credential).to receive(:delete).and_return(true)
    allow(@credentials_proxy).to receive(:retrieve).and_return(credential)
    allow(@credentials_proxy).to receive(:delete).and_return(true)

    # Also stub the old class method for backward compatibility in tests
    allow(DoorFlow::CredentialResource).to receive(:retrieve).and_return(credential) if defined?(DoorFlow::CredentialResource)
    credential
  end

  # Stub person credentials (via credentials proxy)
  def stub_doorflow_person_credentials(person_id, credentials = [])
    resources = credentials.map { |c| mock_resource(c) }
    allow(@credentials_proxy).to receive(:list_for_person).with(person_id).and_return(resources)
  end

  private

  def setup_client_stubs
    # Create proxy doubles
    @people_proxy = double("PeopleProxy")
    @groups_proxy = double("GroupsProxy")
    @credentials_proxy = double("CredentialsProxy")
    @credential_types_proxy = double("CredentialTypesProxy")
    @channels_proxy = double("ChannelsProxy")
    @sites_proxy = double("SitesProxy")
    @roles_proxy = double("RolesProxy")
    @events_proxy = double("EventsProxy")
    @account_proxy = double("AccountProxy")

    # Set up default behaviors
    allow(@people_proxy).to receive(:list).and_return(empty_list_object(DoorFlow::Resources::Person))
    allow(@people_proxy).to receive(:retrieve).and_return(mock_resource(id: 1))
    allow(@people_proxy).to receive(:create).and_return(mock_resource(id: 1))
    allow(@people_proxy).to receive(:delete).and_return(true)

    allow(@groups_proxy).to receive(:list).and_return(empty_list_object(DoorFlow::Resources::Group))

    allow(@credentials_proxy).to receive(:list).and_return(empty_list_object(DoorFlow::Resources::Credential))
    allow(@credentials_proxy).to receive(:list_for_person).and_return([])
    allow(@credentials_proxy).to receive(:create).and_return(mock_resource(id: 1))
    allow(@credentials_proxy).to receive(:delete).and_return(true)

    allow(@credential_types_proxy).to receive(:list).and_return(empty_list_object(DoorFlow::Resources::CredentialType))

    # Default account stub
    default_account = mock_resource(id: "test123", name: "Test Account", user: { email: "test@example.com" })
    allow(@account_proxy).to receive(:retrieve).and_return(default_account)

    # Stub the Client class to return our proxy doubles
    client_double = instance_double(DoorFlow::Client)
    allow(client_double).to receive(:auth).and_return(@auth_double)
    allow(client_double).to receive(:access_token).and_return("test_access_token")
    allow(client_double).to receive(:authenticated?).and_return(true)
    allow(client_double).to receive(:people).and_return(@people_proxy)
    allow(client_double).to receive(:groups).and_return(@groups_proxy)
    allow(client_double).to receive(:credentials).and_return(@credentials_proxy)
    allow(client_double).to receive(:credential_types).and_return(@credential_types_proxy)
    allow(client_double).to receive(:channels).and_return(@channels_proxy)
    allow(client_double).to receive(:sites).and_return(@sites_proxy)
    allow(client_double).to receive(:roles).and_return(@roles_proxy)
    allow(client_double).to receive(:events).and_return(@events_proxy)
    allow(client_double).to receive(:account).and_return(@account_proxy)

    allow(DoorFlow::Client).to receive(:new).and_return(client_double)
    @client_double = client_double
  end

  def empty_list_object(resource_class)
    DoorFlow::ListObject.new(
      data: [],
      total: 0,
      page: 1,
      per_page: 25,
      resource_class: resource_class
    )
  end

  def stub_doorflow_env_vars
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
