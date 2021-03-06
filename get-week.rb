#!/usr/bin/env ruby
 
require "fitgem"
require "pp"
require "yaml"
 
# Load the existing yml config
config = begin
  Fitgem::Client.symbolize_keys(YAML.load(File.open("fitgem.yml")))
rescue ArgumentError => e
  puts "Could not parse YAML: #{e.message}"
  exit
end
 
client = Fitgem::Client.new(config[:oauth])
 
# With the token and secret, we will try to use them
# to reconstitute a usable Fitgem::Client
if config[:oauth][:token] && config[:oauth][:secret]
  begin
    access_token = client.reconnect(config[:oauth][:token], config[:oauth][:secret])
  rescue Exception => e
    puts "Error: Could not reconnect Fitgem::Client due to invalid keys in fitgem.yml"
    exit
  end
# Without the secret and token, initialize the Fitgem::Client
# and send the user to login and get a verifier token
else
  request_token = client.request_token
  token = request_token.token
  secret = request_token.secret
 
  puts "Go to http://www.fitbit.com/oauth/authorize?oauth_token=#{token} and then enter the verifier code below"
  verifier = gets.chomp
 
  begin
    access_token = client.authorize(token, secret, { :oauth_verifier => verifier })
  rescue Exception => e
    puts "Error: Could not authorize Fitgem::Client with supplied oauth verifier"
    exit
  end
 
  puts 'Verifier is: '+verifier
  puts "Token is:    "+access_token.token
  puts "Secret is:   "+access_token.secret
 
  user_id = client.user_info['user']['encodedId']
  puts "Current User is: "+user_id
 
  config[:oauth].merge!(:token => access_token.token, :secret => access_token.secret, :user_id => user_id)
 
  # Write the whole oauth token set back to the config file
  File.open("fitgem.yml", "w") {|f| f.write(config.to_yaml) }
end
 
# ============================================================
# Add Fitgem API calls on the client object below this line
 
# pp client.activities_on_date 'today'
# require 'pry'; binding.pry
#
#
total = 0

puts 'Enter a start date (yyyy-mm-dd): '
start_date = gets.chomp
if (start_date == '')
  date = Date.today
  last_monday = (date - 7)
  start_date = last_monday.to_s
end

puts 'Enter an end date (yyyy-mm-dd): '
end_date = gets.chomp
if (end_date == '')
  date = Date.today
  yesterday = (date - 1)
  end_date = yesterday.to_s
end

current_date = start_date

until current_date > end_date do
  day_val = client.activities_on_date(current_date)['summary']['steps']
  puts current_date + ' => ' + day_val.to_s
  total += day_val
  current_date = (Date.parse(current_date)+1).to_s
end

puts total
