require 'sinatra'
require 'json'

class App < Sinatra::Base
  get '/' do 
    erb :index
  end

  get '/technology/new' do
    @technology = Technology.new.to_json
  end

  get '/event/new' do
    @event = Event.new.to_json
  end

  get '/civilization/new' do
    @civilization = Civilization.new.to_json
  end
end

module Jsonable
  def to_json
    attributes = self.instance_variables
    as_hash = {}
    attributes.each do |a|
      as_hash[a.to_s.gsub("@", "")] = self.send(a.to_s.gsub("@", "")) || ""
    end
    as_hash.to_json
  end
end

class Civilization
  include Jsonable

  attr_reader :status, :technologies, :name

  def initialize(options = {})
    @status = "active"
    @technologies = []
    @name = generate_name
  end

  def generate_name
    "Earf"
  end
end

class Technology
  include Jsonable

  def initialize(options = {})

  end
end

class Event
  include Jsonable

  def initialize(options = {})

  end
end



