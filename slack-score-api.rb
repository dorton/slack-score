require 'bundler'
Bundler.require
Dotenv.load

require 'http'
require 'erb'

class SlackScore

  def formatted
    games = fetch
    b = binding
    ERB.new(File.read("./scores.erb")).result(b)
  end

  def fetch
    payload = {"version"=>"1.4.43", "device"=>"iOS", "msgs"=>[{"method"=>"login", "msgId"=>"ID", "data"=>{"u"=>"#{ENV.fetch("USERNAME")}","p"=>"#{ENV.fetch("PASSWORD")}"}}]}

    response = HTTP.post('http://www.fantrax.com/fxma/req', json: payload)

    fantrax_cookie = response.cookies.find {|c| c.name =="FANTRAX_REMEMBERS" }
    fantrax_cookie = {fantrax_cookie.name => fantrax_cookie.value}

    league_id = JSON.parse(response.body).fetch("responses").first.fetch("data").fetch("leagues").first.fetch("leaguesTeams").first.fetch("leagueId")

    detail_payload = {
        "version"=> "1.4.43",
        "device"=> "iOS",
        "msgs"=> [
            {
                "method"=> "getLeagueHomeInfo",
                "msgId"=> "2",
                "data"=> {}
            }
        ]
    }


    league_data = JSON.parse HTTP
                      .cookies(fantrax_cookie)
                      .post("http://www.fantrax.com/fxma/req?leagueId=#{league_id}", json: detail_payload)
                      .body

    @data = league_data.fetch("responses").find{|j| j["msgId"].to_i == 2}.fetch("data")

    table_data_with_weird_ids = @data.fetch("matchups").fetch("tableData")


    games = []

    table_data_with_weird_ids.each do |row_array|
      game = {}

      game[name_for_team_id(row_array[1])] = row_array[2]
      game[name_for_team_id(row_array[3])] = row_array[4]
      games << game

    end

    games

  end
  def name_for_team_id(team_id)
    @data.fetch("standings").first.fetch("COMBINED").find{|j| j["teamId"].to_s == team_id.to_s}["team"]
  end
end
