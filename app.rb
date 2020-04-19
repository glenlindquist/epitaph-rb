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
    :last_interference,
    :discovery_date,
    :color
  )

  def initialize(options = {})
    @discovery_date = options.fetch(:discovery_date, "BLANK")
    @status = options.fetch(:status, "active")
    @technologies = options.fetch(:technologies, [])
    @name = options.fetch(:name, generate_name)
    @description = options.fetch(:description, generate_description)
    @tech_chance = options.fetch(:tech_chance, generate_tech_chance)
    @event_chances = options.fetch(:event_chances, STARTING_EVENT_CHANCES)
    @vocab = options.fetch(:vocab, generate_vocab)
    @notification_pitch = options.fetch(:notification_pitch, PITCHES.sample)
    @available_technologies = options.fetch(:available_technologies, available_technologies)
    @history = options.fetch(:history, generate_history)
    @last_interference = options.fetch(:last_interference, 0)
    @color = options.fetch(:color, generate_color)
    @size = options.fetch(:size, rand(20) + 10)
  end

  def generate_name
    [
      *('a'..'z'), 'ö', 'ä', 'ü', "á", "č", "ď", 
      "é", "ě", "í", "ň", "ó", "ř", "š", "ť", "ú", 
      "ů", "ý", "ž", "đ", "ă", "â", "ê", "ô", "ơ",
      "ư", "ã", "ắ", "ẹ", "ú", "ỹ", "ì"
    ].sample(rand(3..10)).join.capitalize
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

  def generate_tech_chance
     ((rand * 50 ) / 900) # variable 'ingenuity'
  end

  def generate_color
    Random.new.bytes(3).unpack("H*")[0]
  end

  def trigger_event(event_name, other_vocab)
    if !GameData.event(event_name)
      @history << "No event #{event_name} found."
      return self
    end
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
    if !GameData.technology(technology_name)
      @history << "No tech #{technology_name} found."
      return self
    end
    update_event_chances!(GameData.technology(technology_name)[:event_chances])
    @tech_chance += GameData.technology(technology_name)[:tech_chances] if GameData.technology(technology_name)[:tech_chances]
    @technologies << technology_name
    @available_technologies = available_technologies
    @history << Language.translate(
      text: GameData.technology(technology_name)[:description],
      civ_vocab: vocab,
      other_vocab: other_vocab.merge(GameData.technology(technology_name)[:vocab] || {})
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
        name: "agriculture",
        event_chances: {
          overhunting:  (-3.0 / 1000),
          overfishing:  (-3.0 / 1000),
          crop_failure: (+4.0 / 1000),
          pets:         (+4.0 / 1000),
        },
        description: "The $CIV have begun to cultivate crops, including a type of $CROP.",
        prereqs: [],
      },
      {
        name: "fishing",
        event_chances: {
          overhunting:  (-3.0 / 1000),
          overfishing:  (+4.0 / 1000),
          crop_failure: (-3.0 / 1000),
          food_illness: (+1.0 / 1000),
        },
        description: "The $CIV have learned to catch aquatic creatures such as the $FISH.",
        prereqs: [],
      },
      {
        name: "writing",
        tech_chance: (+ 1.0 / 60),
        event_chances: {
          war_over_metal: (-1.0 / 1000),
          conqueror:      (+3.0 / 1000),
          religion:       (+1.0 / 1000),
        },
        description: "The $CIV have learned writing.",
        prereqs: [],
      },
      {
        name: "astronomy",
        event_chances: {
          religion:  (+1.0 / 1000),
        },
        description: "The $CIV have learned astronomy.",
        prereqs: [],
      },
      {
        name: "fire",
        event_chances: {
          forest_fire:  (+2.0 / 1000),
          food_illness: (-3.0 / 1000),
        },
        description: "The $CIV have learned fire.",
        prereqs: ["toolmaking"],
      },
      {
        name: "metalworking",
        event_chances: {
          war_over_metal: (+3.0 / 1000),
          conqueror:      (+4.0 / 1000),
        },
        description: "The $CIV have learned metalworking.",
        prereqs: ["fire"],
      },
      {
        name: "construction",
        event_chances: {
          large_city:     (+1.0 / 1000),
          city_plague:    (+2.5 / 1000),
          war_over_metal: (-1.0 / 1000),
          forest_fire:    (-2.0 / 1000),
          conqueror:      (+2.0 / 1000),
          pets:           (+1.0 / 1000),
          religion:       (+3.0 / 1000),
        },
        description: "The $CIV have learned construction.",
        prereqs: ["toolmaking", "agriculture"],
      },
      {
        name: "mathematics",
        tech_chance: (+ 1.0 / 60),
        event_chances: {},
        description: "The $CIV have learned mathematics.",
        prereqs: ["astronomy", "astronomy"],
      },
      {
        name: "sailing",
        event_chances: {
          sea_plague:     (+2.0 / 1000),
          large_city:     (+1.0 / 1000),
          war_over_metal: (-2.0 / 1000),
          city_trade:     (+7.0 / 1000)
        },
        description: "The $CIV have learned sailing.",
        prereqs: ["astronomy", "construction"],
      },
      {
        name: "architecture",
        event_chances: {
          large_city: (+5.0 / 1000),
          city_fire:  (-1.0 / 1000),
          religion:   (+5.0 / 1000)
        },
        description: "The $CIV have learned architecture.",
        prereqs: ["construction", "mathematics"],
      },
      {
        name: "plumbing",
        event_chances: {
          large_city:   (+3.0 / 1000),
          city_plague:  (-2.0 / 1000),
          sea_plague:   (-1.0 / 1000)
        },
        description: "The $CIV have learned plumbing.",
        prereqs: ["construction", "metalworking"],
      },
      {
        name: "optics",
        event_chances: {},
        description: "The $CIV have learned optics.",
        prereqs: ["mathematics", "metalworking"],
      },
      {
        name: "alchemy",
        event_chances: {},
        description: "The $CIV have learned alchemy.",
        prereqs: ["mathematics", "metalworking"],
      },
      {
        name: "mill-power",
        event_chances: {},
        description: "The $CIV have learned mill-power.",
        prereqs: ["sailing", "metalworking"],
      },
      {
        name: "gunpowder",
        event_chances: {},
        description: "The $CIV have learned gunpowder.",
        prereqs: ["alchemy"],
      },
      {
        name: "the printing press",
        tech_chance: (+1.0 / 30),
        event_chances: {},
        description: "The $CIV have learned printing.",
        prereqs: ["architecture", "metalworking"],
      },
      {
        name: "taxonomy",
        event_chances: {},
        description: "The $CIV have learned taxonomy.",
        prereqs: ["alchemy", "optics", "the printing press"],
      },
      {
        name: "calculus",
        event_chances: {},
        description: "The $CIV have learned calculus.",
        prereqs: ["optics", "the printing press"],
      },
      {
        name: "rocketry",
        event_chances: {},
        description: "The $CIV have learned rocketry.",
        prereqs: ["calculus", "gunpowder"],
      },
      {
        name: "steam-power",
        event_chances: {},
        description: "The $CIV have learned steam-power.",
        prereqs: ["architecture", "mill-power"],
      },
      {
        name: "electromagnetism",
        event_chances: {},
        description: "The $CIV have learned electromagnetism.",
        prereqs: ["alchemy", "architecture", "mill-power", "the printing press"],
      },
      {
        name: "telegraphy",
        event_chances: {},
        description: "The $CIV have learned telegraphy.",
        prereqs: ["electromagnetism", "steam-power"],
      },
      {
        name: "flight",
        event_chances: {},
        description: "The $CIV have learned flight.",
        prereqs: ["calculus", "electromagnetism", "steam-power"],
      },
      {
        name: "transistors",
        event_chances: {},
        description: "The $CIV have learned transistors.",
        prereqs: ["calculus", "electromagnetism", "steam-power"],
      },
      {
        name: "germ-theory",
        event_chances: {
          city_plague:  (-1.0 / 1000),
          sea_plague:   (-1.0 / 1000)
        },
        description: "The $CIV have learned germ-theory.",
        prereqs: ["calculus", "taxonomy"],
      },
      {
        name: "genetics",
        event_chances: {
          bioterrorism: (+1.0 / 360)
        },
        description: "The $CIV have learned genetics.",
        prereqs: ["germ-theory"],
      },
      {
        name: "nuclear physics",
        event_chances: {
          nuclear_weapons: (+1.0 / 30)
        },
        description: "The $CIV have learned nuclear physics.",
        prereqs: ["calculus", "gunpowder", "telegraphy"],
      },
      {
        name: "mass media",
        event_chances: {},
        description: "The $CIV have developed mass media.",
        prereqs: ["calculus", "telegraphy"],
      },
      {
        name: "digital computers",
        event_chances: {},
        description: "The $CIV have developed digital computers.",
        prereqs: ["transistors"],
      },
      {
        name: "quantum physics",
        event_chances: {},
        description: "The $CIV have developed quantum physics.",
        prereqs: ["nuclear physics"],
      },
      {
        name: "spaceflight",
        event_chances: {
          asteroid: (-1.0 / 1000)
        },
        description: "The $CIV have developed spaceflight.",
        prereqs: ["digital computers", "flight", "rocketry"],
      },
      {
        name: "networked computers",
        tech_chance: (+1.0 / 20),
        event_chances: {
          world_government: (+1.0 / 90)
        },
        description: "The $CIV have developed networked computers.",
        prereqs: ["digital computers", "mass media"],
      },
      {
        name: "artificial intelligence",
        event_chances: {
          skynet: (+1.0 / 180)
        },
        description: "The $CIV have developed artificial intelligence.",
        prereqs: ["networked computers"],
      },
      {
        name: "nanotechnology",
        event_chances: {
          gray_goo: (+1.0 / 180)
        },
        description: "The $CIV have developed nanotechnology.",
        prereqs: ["networked computers", "quantum physics"],
      },
      {
        name: "space colonization",
        event_chances: {
          asteroid: -1,
          volcano: -1,
          world_government: (+2.0 / 90)
        },
        description: "The $CIV have developed space colonization.",
        prereqs: ["nanotechnology", "networked computers", "spaceflight"],
      },
      {
        name: "quantum computers",
        event_chances: {},
        description: "The $CIV have developed quantum computers.",
        prereqs: ["networked computers", "quantum physics"],
      },
      {
        name: "FTL communication",
        event_chances: {},
        description: "The $CIV have developed faster-than-light communication.",
        prereqs: ["artificial intelligence", "quantum computers"],
      },
      {
        name: "FTL travel",
        consequences: {
          status: "pending invite"
        },
        event_chances: {},
        description: "The $CIV have developed faster-than-light travel.",
        prereqs: ["FTL communication", "space colonization"],
      },
    ]
  end

end



