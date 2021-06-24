# frozen_string_literal: true

require "spec_helper"

RSpec.describe PlanningcenterOrbit::Client do
  let(:subject) do
    PlanningcenterOrbit::Client.new(
      orbit_api_key: "12345",
      orbit_workspace: "test",
      pc_api_secret: "123",
      pc_app_id: "abcd"
    )
  end

  it "initializes with arguments passed in directly" do
    expect(subject).to be_truthy
  end

  it "defaults to false for historical import" do
    expect(subject.historical_import).to eq(false)  
  end

  it "allows historical import to be set to true during initialization" do
    client = PlanningcenterOrbit::Client.new(
      orbit_api_key: "12345",
      orbit_workspace: "test",
      pc_api_secret: "123",
      pc_app_id: "abcd",
      historical_import: true
    )

    expect(client.historical_import).to eq(true)
  end

  it "initializes with credentials from environment variables" do
    allow(ENV).to receive(:[]).with("ORBIT_API_KEY").and_return("12345")
    allow(ENV).to receive(:[]).with("ORBIT_WORKSPACE").and_return("test")
    allow(ENV).to receive(:[]).with("PLANNING_CENTER_API_SECRET").and_return("123")
    allow(ENV).to receive(:[]).with("PLANNING_CENTER_APP_ID").and_return("abcd")

    expect(PlanningcenterOrbit::Client).to be_truthy
  end
end