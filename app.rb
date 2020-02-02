require 'sinatra'
require 'json'

class Hash
  def recursive_symbolize!
    self.each do |k, v|
      v.recursive_symbolize! if v.class == Hash
    end
    self.transform_keys!(&:to_sym)
  end
end

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
    civ_params = @request_payload["civilization"].recursive_symbolize!

    Civilization.new(civ_params).
      acquire_technology(technology_name, @other_vocab).
      to_json

  end

  post '/trigger_event' do
    request.body.rewind
    @request_payload = JSON.parse(request.body.read)
    event_name = @request_payload["event_name"]
    civ_params = @request_payload["civilization"].recursive_symbolize!

    Civilization.new(civ_params).
      trigger_event(event_name, @other_vocab).
      to_json

  end

  get '/new_civilization' do
    Civilization.new(discovery_date: params[:stardate]).to_json
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
  def from_json(string)
    JSON.load(string).each do |var, val|
      self.instance_variable_set var, val
    end
  end
end

class Civilization
  include JSONable

  STARTING_TECH_CHANCE = (1.0 / 900)
  STARTING_EVENT_CHANCES = {
    asteroid:         (1.0 / 1000),
    volcano:          (1.0 / 1000),
    food_illness:     (1.0 / 1000),
    gamma_ray_burst:  (1.0 / 3000),
    pets:             (1.0 / 1000)
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
    :available_technologies,
    :history,
    :last_interference
  )

  def initialize(options = {})
    @discovery_date = options.fetch(:discovery_date, "BLANK")
    @status = options.fetch(:status, "active")
    @technologies = options.fetch(:technologies, [])
    @name = options.fetch(:name, generate_name)
    @description = options.fetch(:description, generate_description)
    @tech_chance = options.fetch(:tech_chance, STARTING_TECH_CHANCE)
    @event_chances = options.fetch(:event_chances, STARTING_EVENT_CHANCES)
    @vocab = options.fetch(:vocab, generate_vocab)
    @notification_pitch = options.fetch(:notification_pitch, PITCHES.sample)
    @available_technologies = options.fetch(:available_technologies, available_technologies)
    @history = options.fetch(:history, generate_history)
    @last_interference = options.fetch(:last_interference, 0)
  end

  def generate_name
    ('a'..'z').to_a.sample(rand(5..10)).join.capitalize
  end

  def generate_description
    "A blue marble!"
  end

  def generate_vocab
    {
      beast:      "tiger",
      city:       "Nashville",
      civ:        name,
      conqueror:  "Bernie",
      crop:       "corn",
      fish:       "koi",
      pet:        "doggo",
      planet:     "Earf",
      religion:   "Scientology",
      system:     "sol"
    }
  end

  def generate_history
    [
      "The #{@name} were discovered in #{@discovery_date}."
    ]
  end

  def trigger_event(event_name, other_vocab)
    GameData.event(event_name)[:consequences].each do |var_name, value|
      self.instance_variable_set("@" + var_name.to_s, value)
    end
    @history << Language.translate(
      text: GameData.event(event_name)[:description],
      civ_vocab: vocab,
      other_vocab: other_vocab
    )
    self
  end

  def acquire_technology(technology_name, other_vocab)
    update_event_chances!(GameData.technology(technology_name)[:event_chances])
    @technologies << technology_name
    @available_technologies = available_technologies
    @history << Language.translate(
      text: GameData.technology(technology_name)[:description],
      civ_vocab: vocab,
      other_vocab: other_vocab
    )
    self
  end

  def update_event_chances!(new_chances)
    new_chances.each do |event, chance|
      if !!@event_chances[event]
        @event_chances[event] += chance
      else
        @event_chances[event] = chance
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
      text = text.gsub(word, vocab[clean(word)] || "BLANK")
    end

    text
  end

  def clean(word)
    word.gsub("$", "").downcase.to_sym
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
      {
        name: "overhunting",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "overfishing",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "crop_failure",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "food_illness",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "pets",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "conqueror",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "volcano",
        description: "Big rock make $PLANET go big boom.",
        consequences: {
          status: "extinct"
        }
      },
      {
        name: "gamma_ray_burst",
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
      {
        name: "butt-stuff",
        event_chances: {
          overhunting:  (+4.0 / 1000),
          overfishing:  (-3.0 / 1000),
          crop_failure: (-3.0 / 1000),
          food_illness: (+1.0 / 1000),
          pets:         (+3.0 / 1000),
          conqueror:    (+1.0 / 1000)
        },
        description: "The $CIV use butt-stuff for hunting the wild $BEAST.",
        prereqs: [],
      },
      {
        name: "chiropractice",
        event_chances: {
          overhunting:  (+4.0 / 1000),
          overfishing:  (-3.0 / 1000),
          crop_failure: (-3.0 / 1000),
          food_illness: (+1.0 / 1000),
          pets:         (+3.0 / 1000),
          conqueror:    (+1.0 / 1000)
        },
        description: "The $CIV use chiropractice for hunting the wild $BEAST.",
        prereqs: [],
      },
    ]
  end

end



