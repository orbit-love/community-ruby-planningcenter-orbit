#!/usr/bin/env ruby
# frozen_string_literal: true

# require "planningcenter_orbit"
require "thor"

module PlanningcenterOrbit
  module Scripts
    class CheckEventCheckins < Thor
      desc "render", "check for new event check-ins and push them to Orbit"
      def render(*params)
        client = PlanningcenterOrbit::Client.new(historical_import: params[0])
        client.check_ins
      end
    end
  end
end