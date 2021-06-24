# frozen_string_literal: true

require "dotenv/load"
require "net/http"
require "json"

# Create a client to log Planning Center interactions in your Orbit workspace
# Credentials can either be passed in to the instance or be loaded
# from environment variables
#
# @example
#   client = PlanningcenterOrbit::Client.new
#
# @option params [String] :orbit_api_key
#   The API key for the Orbit API
#
# @option params [String] :orbit_workspace
#   The workspace ID for the Orbit workspace
#
# @option params [String] :pc_app_id
#   The Planning Center application ID obtained from Planning Center's dashboard
#
# @option params [String] :pc_api_secret
#   The Planning Center API secret obtained from Planning Center's dashboard
#
# @option params [Boolean] :historical_import
#   Boolean flag to indicate whether to import all historical activities to Orbit.
#   Default is false.
#
# @param [Hash] params
#
# @return [PlanningcenterOrbit::Client]
#
module PlanningcenterOrbit
  class Client
    attr_accessor :orbit_api_key, :orbit_workspace, :pc_app_id, :pc_api_secret, :historical_import

    def initialize(params = {})
      @orbit_api_key = params.fetch(:orbit_api_key, ENV["ORBIT_API_KEY"])
      @orbit_workspace = params.fetch(:orbit_workspace, ENV["ORBIT_WORKSPACE_ID"])
      @pc_app_id = params.fetch(:pc_app_id, ENV["PLANNING_CENTER_APP_ID"])
      @pc_api_secret = params.fetch(:pc_api_secret, ENV["PLANNING_CENTER_API_SECRET"])
      @historical_import = params.fetch(:historical_import, false)
    end

    def check_ins
      PlanningcenterOrbit::Planningcenter.new(
        pc_app_id: @pc_app_id,
        pc_api_secret: @pc_api_secret,
        orbit_api_key: @orbit_api_key,
        orbit_workspace: @orbit_workspace,
        historical_import: @historical_import
      ).process_checkins
    end
  end
end