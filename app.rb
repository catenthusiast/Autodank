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

class LinkPoster
  include Sidekiq::Worker
  def perform(title, subreddit, linkurl)
    $client.submit(title, subreddit, options = {:url => linkurl})
  end
end

class TextPoster
  include Sidekiq::Worker
  def perform(title, subreddit, selftext)
    $client.submit(title, subreddit, options = {:text => selftext})
  end
end

class Autodank < Sinatra::Application
  get '/' do
    haml :index
  end

  get '/link' do
    haml :link
  end

  post '/link' do
    title = params[:title]
    subreddit = params[:subreddit]
    linkurl = params[:url]
    inputtime = params[:time]
    time = Time.parse(inputtime)
    LinkPoster.perform_at(time, title, subreddit, linkurl)
  end

  get '/text' do
    haml :text
  end

  post '/text' do
    title = params[:title]
    subreddit = params[:subreddit]
    selftext = params[:text]
    inputtime = params[:time]
    time = Time.parse(inputtime)
    TextPoster.perform_at(time, title, subreddit, selftext)
  end
end
