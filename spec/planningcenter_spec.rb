# frozen_string_literal: true

require "spec_helper"

RSpec.describe PlanningcenterOrbit::Planningcenter do
  let(:subject) do
    PlanningcenterOrbit::Planningcenter.new(
      orbit_workspace: "1234",
      orbit_api_key: "12345",
      pc_app_id: "abcd",
      pc_api_secret: "123"
    )
  end

  describe "#get_events" do
    context "with no events" do
      it "returns a string message" do
        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": []}", headers: {})

        expect(subject.get_events).to eql("No new events from your Planning Center organization.\nIf you suspect this is incorrect, verify your Planning Center credentials are correct.\n")
      end
    end

    context "with events returned" do
      it "returns the response properly formatted" do
        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": [{\"type\": \"Event\", \"id\": \"56789\", \"attributes\": {\"created_at\": \"2021-06-23T11:49:30Z\", \"name\": \"Test Event\"}, \"links\": {\"self\": \"https://api.planningcenteronline.com/check-ins/v2/events/56789\"}}]}", headers: {})

        expect(subject.get_events).to eql(
          {
            "data"=>[
              {
                "type"=>"Event",
                "id"=>"56789", 
                "attributes"=>{
                  "created_at"=>"2021-06-23T11:49:30Z",
                  "name"=>"Test Event"
                }, 
                "links"=>{
                  "self"=>"https://api.planningcenteronline.com/check-ins/v2/events/56789"
                }
              }
            ]
          }
        )
      end
    end
  end

  describe "#get_event_checkins" do
    context "when it returns the data" do
      it "returns the response properly formatted" do
        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events/56789/check_ins").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": [{\"type\": \"CheckIn\", \"id\": \"123456789\", \"attributes\": {\"created_at\": \"2021-06-23T11:49:30Z\", \"first_name\": \"Ploni\", \"last_name\": \"Almoni\"}}]}", headers: {})      

        expect(subject.get_event_checkins(link: "https://api.planningcenteronline.com/check-ins/v2/events/56789/check_ins")).to eql(
          [
            {
              "type"=>"CheckIn",
              "id"=>"123456789",
              "attributes"=>{
                "created_at"=>"2021-06-23T11:49:30Z",
                "first_name"=>"Ploni",
                "last_name"=>"Almoni"
              }
            }
          ]
        )
      end
    end
  end

  describe "#process_checkins" do
    context "with historical import set to false and no newer items than the latest activity for the type in Orbit" do
      it "does not send any items to Orbit" do
        stub_const("PlanningcenterOrbit::Orbit", double)
        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": [{\"type\": \"Event\", \"id\": \"56789\", \"attributes\": {\"created_at\": \"2021-06-20T11:49:30Z\", \"name\": \"Test Event\"}, \"links\": {\"self\": \"https://api.planningcenteronline.com/check-ins/v2/events/56789\"}}]}", headers: {})

        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events/56789/check_ins").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": [{\"type\": \"CheckIn\", \"id\": \"123456789\", \"attributes\": {\"created_at\": \"2021-06-20T11:49:30Z\", \"first_name\": \"Ploni\", \"last_name\": \"Almoni\"}}]}", headers: {})

        stub_request(:get, "https://app.orbit.love/api/v1/1234/activities?activity_type=custom:planning_center:check_in&direction=DESC&items=10")
        .with(
        headers: { 'Authorization' => "Bearer 12345", 'Accept' => 'application/json', 'User-Agent'=>"community-ruby-planningcenter-orbit/#{PlanningcenterOrbit::VERSION}" }
        )
        .to_return(
            status: 200,
            body: {
                data: [
                    {
                        id: "6",
                        type: "spec_activity",
                        attributes: {
                            action: "spec_action",
                            created_at: "2021-06-23T16:03:02.052Z",
                            key: "spec_activity_key#1",
                            occurred_at: "2021-04-01T16:03:02.050Z",
                            type: "SpecActivity",
                            tags: "[\"spec-tag-1\"]",
                            orbit_url: "https://localhost:3000/test/activities/6",
                            weight: "1.0"
                        },
                        relationships: {
                            activity_type: {
                                data: {
                                    id: "20",
                                    type: "activity_type"
                                }
                            }
                        },
                        member: {
                            data: {
                                id: "3",
                                type: "member"
                            }
                        }
                    }
                ]
            }.to_json.to_s,
            headers: {}
        )

        expect(subject.process_checkins).to eql("Sent 0 checkins to your Orbit workspace")
      end
    end

    context "with historical import set to false and a newer item than the latest activity for its type in Orbit" do
      it "sends the item to Orbit" do
        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": [{\"type\": \"Event\", \"id\": \"56789\", \"attributes\": {\"created_at\": \"2021-06-20T11:49:30Z\", \"name\": \"Test Event\"}, \"links\": {\"self\": \"https://api.planningcenteronline.com/check-ins/v2/events/56789\"}}]}", headers: {})

        stub_request(:get, "https://api.planningcenteronline.com/check-ins/v2/events/56789/check_ins").
        with(
          headers: {
            'Accept'=>'application/json',
            'Content-Type'=>'application/json'
          }).
        to_return(status: 200, body: "{\"data\": [{\"type\": \"CheckIn\", \"id\": \"123456789\", \"attributes\": {\"created_at\": \"2021-06-23T11:49:30Z\", \"first_name\": \"Ploni\", \"last_name\": \"Almoni\"}}]}", headers: {})

        stub_request(:get, "https://app.orbit.love/api/v1/1234/activities?activity_type=custom:planning_center:check_in&direction=DESC&items=10")
        .with(
        headers: { 'Authorization' => "Bearer 12345", 'Accept' => 'application/json', 'User-Agent'=>"community-ruby-planningcenter-orbit/#{PlanningcenterOrbit::VERSION}" }
        )
        .to_return(
            status: 200,
            body: {
                data: [
                    {
                        id: "6",
                        type: "spec_activity",
                        attributes: {
                            action: "spec_action",
                            created_at: "2021-06-19T16:03:02.052Z",
                            key: "spec_activity_key#1",
                            occurred_at: "2021-04-01T16:03:02.050Z",
                            type: "SpecActivity",
                            tags: "[\"spec-tag-1\"]",
                            orbit_url: "https://localhost:3000/test/activities/6",
                            weight: "1.0"
                        },
                        relationships: {
                            activity_type: {
                                data: {
                                    id: "20",
                                    type: "activity_type"
                                }
                            }
                        },
                        member: {
                            data: {
                                id: "3",
                                type: "member"
                            }
                        }
                    }
                ]
            }.to_json.to_s,
            headers: {}
        )

        stub_request(:post, "https://app.orbit.love/api/v1/1234/activities").
        with(
          body: "{\"activity\":{\"activity_type\":\"planning_center:check_in\",\"tags\":[\"channel:planning_center\"],\"key\":\"123456789\",\"title\":\"New guest check-in for Test Event\",\"description\":\"Ploni Almoni checked in for Test Event on Planning Center\",\"occurred_at\":\"2021-06-23T11:49:30Z\",\"link\":\"https://check-ins.planningcenteronline.com/events/56789\",\"link_text\":\"Link to Planning Center Event\",\"member\":{\"name\":\"Ploni Almoni\"}},\"identity\":{\"source\":\"planning_center\",\"username\":\"ploni-almoni\"}}",
          headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization'=>'Bearer 12345',
          'Content-Type'=>'application/json',
          'Host'=>'app.orbit.love',
          'User-Agent'=>"community-ruby-planningcenter-orbit/#{PlanningcenterOrbit::VERSION}"
          }).
        to_return(status: 200, body: {
          response: {
            code: 'SUCCESS'
          }}.to_json.to_s, headers: {})

        expect(subject.process_checkins).to eql("Sent 1 checkins to your Orbit workspace")
      end
    end
  end
end