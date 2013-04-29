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

puts 'Enter an end date (yyyy-mm-dd): '
end_date = gets.chomp


start_date = start_date.split('-')
end_date = end_date.split('-')

if start_date[1] == end_date[1] and start_date[0] == end_date[0] 
  for day in start_date[2] .. end_date[2] do
    if Date.valid_date?(start_date[0].to_i,start_date[1].to_i,day.to_i)
      date_s = start_date[0] + '-' + start_date[1] + '-' + day
      day_val = client.activities_on_date(date_s)['summary']['steps']
      puts date_s + ' => ' + day_val.to_s
      total += day_val
    end
  end
  puts total
else 
  puts 'trickier case -- will handle for next week'
end

