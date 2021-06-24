# frozen_string_literal: true

require "zeitwerk"
require "orbit_activities"
require_relative "planningcenter_orbit/version"

module PlanningcenterOrbit
  loader = Zeitwerk::Loader.new
  loader.tag = File.basename(__FILE__, ".rb")
  loader.push_dir(__dir__)
  loader.setup
end