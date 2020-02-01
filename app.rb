require 'sinatra'
require 'json'

class App < Sinatra::Base
  before do
    @other_vocab = {
      "$STARDATE" => params[:stardate] || "NONE"
    }
  end

  get '/' do 
    erb :index
  end

  post '/acquire_technology' do
    request.body.rewind
    @request_payload = JSON.parse(request.body.read)
    technology_name = @request_payload["technology_name"]
    civ_params =  @request_payload["civilization"]

    pp technology_name

    civilization = Civilization.new(civ_params).acquire_technology(technology_name)

    technology_text = Language.translate(
      text: GameData.technology(technology_name)[:description],
      civ_vocab: civilization.vocab,
      other_vocab: @other_vocab
    )
    {
      civilization: civilization,
      technology_text: technology_text
    }.to_json
  end

  post '/trigger_event' do
    event_name = params[:event_name]
    civilization = Civilization.new(JSON.parse(params[:civilization])).trigger_event(event_name)

    event_text = Language.translate(
      text: GameData.event(event_name)[:description],
      civ_vocab: civilization.vocab,
      other_vocab: @other_vocab
    )

    {
      civilization: civilization,
      event_text: event_text
    }
  end

  get '/new_civilization' do
    Civilization.new.to_json
  end
end

module JSONable
  def to_json(options = {})
      hash = {}
      self.instance_variables.each do |var|
          hash[var.to_s.gsub("@", "")] = self.instance_variable_get var
      end
      hash.to_json
  end
  def from_json! string
      JSON.load(string).each do |var, val|
          self.instance_variable_set var, val
      end
  end
end

class Civilization
  include JSONable

  STARTING_TECH_CHANCE = (1.0 / 90)
  STARTING_EVENT_CHANCES = {
    asteroid:         (1.0 / 1000),
    volcano:          (1.0 / 1000),
    food_illness:     (1.0 / 1000),
    gamma_ray_burst:  (1.0 / 3000),
    pets:             (1 / 1000)
  }
  PITCHES = ["C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5", "E5", "F5", "G5", "A5", "B5"]

  attr_reader(
    :status,
    :technologies,
    :name,
    :description,
    :event_chances,
    :tech_chance,
    :vocab,
    :notification_pitch,
    :available_technologies
  )

  def initialize(options = {})
    @status = options.fetch(:status, "active")
    @technologies = options.fetch(:technologies, [])
    @name = options.fetch(:name, generate_name)
    @description = options.fetch(:description, generate_description)
    @tech_chance = options.fetch(:tech_chance, STARTING_TECH_CHANCE)
    @event_chances = options.fetch(:event_chances, STARTING_EVENT_CHANCES)
    @vocab = options.fetch(:vocab, generate_vocab)
    @notification_pitch = options.fetch(:notification_pitch, PITCHES.sample)
    @available_technologies = options.fetch(:available_technologies, available_technologies)
  end

  def generate_name
    "Human"
  end

  def generate_description
    "A blue marble!"
  end

  def generate_vocab
    {
      "$BEAST"        => "tiger",
      "$CITY"         => "Nashville",
      "$CIVILIZATION" => name,
      "$CONQUEROR"    => "Bernie",
      "$CROP"         => "corn",
      "$FISH"         => "koi",
      "$PET"          => "doggo",
      "$PLANET"       => "Earf",
      "$RELIGION"     => "Scientology",
      "$SYSTEM"       => "Sol"
    }
  end

  def trigger_event(event_name)
    GameData.event(event_name)[:consequences].each do |att, value|
      self.send(att, value)
    end
    self
  end

  def acquire_technology(technology_name)
    update_event_chances!(GameData.technology(technology_name)[:event_chances])
    @technologies << technology_name
    @available_technologies = available_technologies
    self
  end

  def update_event_chances!(new_chances)
    new_chances.each do |chance, value|
      if !!event_chances[chance]
        @event_chances[chance] += value
      else
        @event_chances[chance] = value
      end
    end
  end

  def available_technologies
    # grabs names only
    GameData.technologies.
      select{|tech| tech[:prereqs] - @technologies == [] }.
      map{|tech| tech[:name]} -
      @technologies
  end

end

module Language
  extend self
  def translate(options = {})
    text = options.fetch(:text, "")
    civ_vocab = options.fetch(:civ_vocab, {})
    other_vocab = options.fetch(:other_vocab, {})
    vocab = civ_vocab.merge(other_vocab)

    words_to_translate = text.scan(/\$[A-Z]*/)

    words_to_translate.each do |word|
      text = text.gsub(word, vocab[word] || "BLANK")
    end

    text
  end
end

module GameData
  extend self

  def event(name)
    events.find{|e| e[:name] == name }
  end

  def technology(name)
    technologies.find{|t| t[:name] == name }
  end

  def events
    [
      {
        name: "asteroid",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
    ]
  end

  def technologies
    [
      {
        name: "toolmaking",
        event_chances: {
          overhunting:  (+4.0 / 1000),
          overfishing:  (-3.0 / 1000),
          crop_failure: (-3.0 / 1000),
          food_illness: (+1.0 / 1000),
          pets:         (+3.0 / 1000),
          conqueror:    (+1.0 / 1000)
        },
        description: "The $CIV use stone tools for hunting the wild $BEAST.",
        prereqs: [],
      },
      
    ]
  end

end



