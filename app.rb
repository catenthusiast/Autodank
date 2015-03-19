#!/usr/bin/env ruby

require 'time'
require 'sidekiq'
require 'redditkit'
require 'sinatra/base'
require 'haml'

Sidekiq.configure_client do |config|
  config.redis = { :namespace => 'x', :size => 1 }
end

Sidekiq.configure_server do |config|
  config.redis = { :namespace => 'x' }
end

REDDIT_USERNAME = ENV['REDDIT_USERNAME']
REDDIT_PASSWORD = ENV['REDDIT_PASSWORD']

$client = RedditKit::Client.new REDDIT_USERNAME, REDDIT_PASSWORD

class Poster
  include Sidekiq::Worker
  def perform(title, subreddit)
    $client.submit(title, subreddit)
  end
end

class Autodank < Sinatra::Application
  get '/submit' do
    haml :form
  end

  post '/submit' do
    title = params[:title]
    subreddit = params[:subreddit]
    inputtime = params[:time]
    time = Time.parse(inputtime)
    Poster.perform_at(time, title, subreddit)
  end
end
