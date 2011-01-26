module Redistat
  class Event
    include Database
    
    attr_reader :id
    attr_reader :key
    attr_reader :connection_ref
    
    attr_accessor :stats
    attr_accessor :meta
    attr_accessor :options
    
    def initialize(scope, label = nil, date = nil, stats = {}, options = {}, meta = {}, is_new = true)
      @options = parse_options(options)
      @connection_ref = @options[:connection_ref]
      @key = Key.new(scope, label, date, @options)
      @stats = stats ||= {}
      @meta = meta ||= {}
      @new = is_new
    end
    
    def db
      super(@connection_ref)
    end
    
    def parse_options(options)
      default_options.each do |opt, val|
        options[opt] = val if options[opt].nil?
      end
      options
    end

    def default_options
      { :depth => :hour, :store_event => false, :connection_ref => nil }
    end
    
    def new?
      @new
    end
    
    def date
      @key.date
    end
    
    def date=(input)
      @key.date = input
    end
    
    def scope
      @key.scope
    end
    
    def scope=(input)
      @key.scope = input
    end
    
    def label
      @key.label
    end
    
    def label_hash
      @key.label_hash
    end
    
    def label=(input)
      @key.label = input
    end

    def next_id
      db.incr("#{self.scope}#{KEY_NEXT_ID}")
    end
    
    def save
      return false if !self.new?
      Summary.update_all(@key, @stats, depth_limit, expiration, @connection_ref)
      if @options[:store_event]
        @id = self.next_id
        db.hmset("#{self.scope}#{KEY_EVENT}#{@id}",
                 "scope", self.scope,
                 "label", self.label,
                 "date", self.date.to_time.to_s,
                 "stats", self.stats.to_json,
                 "meta", self.meta.to_json,
                 "options", self.options.to_json)
        db.sadd("#{self.scope}#{KEY_EVENT_IDS}", @id)
      end
      @new = false
      self
    end
    
    def depth_limit
      @options[:depth] ||= @key.depth
    end

    def expiration
      @options[:expire] ||= {}
    end

    def self.create(*args)
      self.new(*args).save
    end
    
    def self.find(scope, id)
      event = db.hgetall "#{scope}#{KEY_EVENT}#{id}"
      return nil if event.size == 0
      self.new( event["scope"], event["label"], event["date"], JSON.parse(event["stats"]),
                JSON.parse(event["meta"]), JSON.parse(event["options"]), false )
    end
    
  end
end
