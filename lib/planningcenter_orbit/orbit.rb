
# frozen_string_literal: true

module PlanningcenterOrbit
  class Orbit
    def self.call(type:, data:, workspace_id:, api_key:)
      if type == "checkin"
        PlanningcenterOrbit::Interactions::Checkin.new(
          event_title: data[:title],
          checkin: data[:checkin],
          url: data[:url],
          workspace_id: workspace_id,
          api_key: api_key
        )
      end
    end
  end
end