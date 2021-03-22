#!/usr/bin/env ruby
# frozen_string_literal: true

# Copyright (c) 2021 Samuel Y. Ayele

require 'json'
require 'byebug'
require 'assign_utc_offsets'
class TweetBack
  TREND_LOCATIONS_FILE = 'locations/available_locs_for_trend.json'
  TREND_LOCATIONS_UTC_FILE = 'locations/utc_offset_assigned_available_locations_grouped.json'
  def strike
    puts '[tweetback] TWEETBACK WITH TRENDING TWEETS FOR A TIMEZONE'
    puts '[tweetback] ENTER UTC OFFSET (e.g. -7 or +2.5)'
    utc_offset = "UTC#{gets.chomp.strip}"
    show_message("getting trending tweets for places with utc #{utc_offset}", 'notice')
    utc_locations = target_utc(utc_offset)
    target_locations = extract_cities(utc_locations)
    get_high_v_trending_tweets(target_locations) # returns
    # an array of trending high volume tweets
    # tweet_tails = set_tweet_tails(high_v_trending_tweets) # these would then
    # be permutated
    show_message('tweet tails assigned. now, input your tweet head', 'notice')
    tweet_head = gets.chomp.strip
    # formed_tweets = setup_tweets(tweet_head, tweet_tails)
    # returns a string for each trending tweet
    show_message('tweets now all ready to be sent out', 'notice')
    sleep 6
    # tweets_sent = send_out_tweets(formed_tweets)
    show_message('all tweets sent successfully.', 'notice')
    tweet_head
  end

  def show_message(message, type)
    case type
    when 'notice'
      puts "[tweetback] [NOTICE] #{message}".upcase
    when 'error'
      puts "[tweetback] [ERROR] #{message}".upcase
    when 'warning'
      puts "[tweetback] [WARNING] #{message}".upcase
    end
  end

  def create_folder(folder_name)
    Process.spawn("mkdir #{folder_name}/")
  end

  def create_json_file(file_name, json_entries)
    File.write("JSON/#{file_name}.json",
               JSON.dump(json_entries))
  end

  def prompt_entry(attributes)
    puts "[tweetback] INPUT JSON DATA FOR FIELD NAMES: #{attributes}"
    puts "[tweetback] 'ENTER' TO QUIT"
  end

  def send_out_tweets
    # strike back!
  end

  def target_utc(utc_offset)
    if File.exist?(TREND_LOCATIONS_UTC_FILE)
      # process getting available_locations and assigning utc done before, use it
    else
      available_locations # run python script and
      sort_out_utc_locations
    end
    match_utc(utc_offset)
  end

  def extract_cities(utc_locations)
    location_names = []
    utc_locations.first[1].each do |location|
      location_names << location['name']
    end
    location_names
  end

  def get_high_v_trending_tweets(target_locations)
    get_trending_list(target_locations)
    # loop to call python class for all the locations in the same utc offset
    high_volume_tweets
    # keep only those with higer number of tweet volumes
  end

  def get_trending_list(target_locations)
    create_folder('trending_tweets')
    target_locations.each do |location|
      show_message("getting trending tweets for #{location}", 'notice')
      Process.spawn('. ~/workspace/python-virtual-environments/tweepy/bin/'\
        'activate && python3 ~/workspace/python-virtual-environments/tweepy/'\
        "include/get_trending_tweets.py #{location} && deactivate")
      sleep 2
      Process.spawn("mv #{Dir.pwd}/twitter_#{location}_trend*.json "\
        '~/workspace/bt-strike/trending_tweets')
    end
  end

  def high_volume_tweets
    # once a trending json was returned for a target, go through the json result
    # select only those relevant ones depending on a criteria
  end

  def available_locations
    Process.spawn('. ~/workspace/python-virtual-environments/tweepy/bin/'\
      'activate && python3 ~/workspace/python-virtual-environments/tweepy/'\
      'include/get_trending_tweets.py && deactivate')
    Process.spawn('mv ~/workspace/python-virtual-environments/tweepy/include'\
      '/available_locs_for_trend.json ~/workspace/bt-strike/locations')
    # Process.spawn("deactivate")
  end

  def match_utc(utc_offset)
    matched_locations = []
    file = File.read(TREND_LOCATIONS_UTC_FILE.to_s)
    json_data = JSON.parse(file)
    json_data.each do |locations|
      next unless locations.first[/UTC/]

      matched_locations << locations if locations.first == utc_offset
    end
    matched_locations
  end

  def sort_out_utc_locations
    AssignUtcOffsets.start_processing(TREND_LOCATIONS_FILE)
    Process.spawn('mv utc_offset_assigned_available_locations.json locations/'\
      'utc_offset_assigned_available_locations.json')
    Process.spawn('mv utc_offset_assigned_available_locations_grouped.json locations/'\
      'utc_offset_assigned_available_locations_grouped.json')
  end
end

# get me all trending, for utc+3,
# avoid duplicates, and further fiter out less relevant ones, save it
# as json with the utc value used and using "last update time" as file name
tbstriker = TweetBack.new
tbstriker.strike
