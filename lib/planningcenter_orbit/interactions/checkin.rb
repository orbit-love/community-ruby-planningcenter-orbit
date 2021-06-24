# frozen_string_literal: true

require "json"

module PlanningcenterOrbit
  module Interactions
    class Checkin
      def initialize(event_title:, url:, checkin:, workspace_id:, api_key:)
        @event_title = event_title
        @url = url
        @id = checkin["id"]
        @created_at = checkin["attributes"]["created_at"]
        @guest = "#{checkin["attributes"]["first_name"]} #{checkin["attributes"]["last_name"]}"
        @workspace_id = workspace_id
        @api_key = api_key

        after_initialize!
      end

      def after_initialize!
        OrbitActivities::Request.new(
          api_key: @api_key,
          workspace_id: @workspace_id,
          user_agent: "community-ruby-planningcenter-orbit/#{PlanningcenterOrbit::VERSION}",
          action: "new_activity",
          body: construct_body.to_json
        )
      end

      def construct_body
        {
          activity: {
            activity_type: "planning_center:check_in",
            tags: ["channel:planning_center"],
            key: @id,
            title: "New guest check-in for #{@event_title}",
            description: "#{@guest} checked in for #{@event_title} on Planning Center",
            occurred_at: @created_at,
            link: @url,
            link_text: "Link to Planning Center Event",
            member: {
              name: @guest
            }
          },
          identity: {
            source: "planning_center",
            username: @guest.parameterize
          }
        }
      end
    end
  end
end