# frozen_string_literal: true

require "active_support/time"

module PlanningcenterOrbit
  class Planningcenter
    def initialize(params = {})
      @pc_app_id = params.fetch(:pc_app_id)
      @pc_api_secret = params.fetch(:pc_api_secret)
      @orbit_api_key = params.fetch(:orbit_api_key)
      @orbit_workspace = params.fetch(:orbit_workspace)
      @historical_import = params.fetch(:historical_import, false)
    end

    def process_checkins
      events = get_events

      return "Something went wrong with the Planning Center API" unless events["data"].is_a?(Array)

      events["data"].each do |event|
        checkins = get_event_checkins(link: "#{event["links"]["self"]}/check_ins")

        next if checkins.nil? || checkins.empty?

        times = 0
        checkins.each do |checkin|
          unless @historical_import && last_orbit_activity_timestamp
            next if checkin["attributes"]["created_at"] < last_orbit_activity_timestamp
          end

          unless last_orbit_activity_timestamp.nil? || last_orbit_activity_timestamp.empty?
            next if checkin["attributes"]["created_at"] < last_orbit_activity_timestamp
          end

          times += 1 
          PlanningcenterOrbit::Orbit.call(
            type: "checkin",
            data: {
              checkin: checkin,
              title: event["attributes"]["name"],
              url: "https://check-ins.planningcenteronline.com/events/#{event["id"]}"
            },
            workspace_id: @orbit_workspace,
            api_key: @orbit_api_key
          )
        end

        return "Sent #{times} checkins to your Orbit workspace"
      end
    end

    def get_events
      url = URI("https://api.planningcenteronline.com/check-ins/v2/events")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request.basic_auth @pc_app_id, @pc_api_secret

      response = https.request(request)

      response = JSON.parse(response.body)

      if response["data"].nil? || response["data"].empty?
        return <<~HEREDOC
          No new events from your Planning Center organization.
          If you suspect this is incorrect, verify your Planning Center credentials are correct.
        HEREDOC
      end

      response
    end

    def get_event_checkins(link:)
      url = URI(link)
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(url)
      request["Accept"] = "application/json"
      request["Content-Type"] = "application/json"
      request.basic_auth @pc_app_id, @pc_api_secret

      response = https.request(request)

      response = JSON.parse(response.body)

      response["data"]
    end

    private

    def last_orbit_activity_timestamp
      @last_orbit_activity_timestamp ||= begin
        OrbitActivities::Request.new(
          api_key: @orbit_api_key,
          workspace_id: @orbit_workspace,
          user_agent: "community-ruby-planningcenter-orbit/#{PlanningcenterOrbit::VERSION}",
          action: "latest_activity_timestamp",
          filters: { activity_type: "custom:planning_center:check_in" }
        ).response
      end
    end
  end
end