require 'rubygems'
require 'bundler'

Bundler.require

require "./app"

run Autodank

require 'sidekiq/web'
run Rack::URLMap.new('/' => Autodank, '/sidekiq' => Sidekiq::Web)
