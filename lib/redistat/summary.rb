module Redistat
  class Summary
    include Database

    def self.update_all(key, stats = {}, depth_limit = nil, time_to_live = {}, connection_ref = nil)
      stats ||= {}
      depth_limit ||= key.depth
      return nil if stats.size == 0
      Date::DEPTHS.each do |depth|
        update(key, stats, depth, time_to_live[depth], connection_ref)
        break if depth == depth_limit
      end
    end

    private

    def self.update(key, stats, depth, time_to_live = nil, connection_ref = nil)
      stats.each do |field, value|
        db(connection_ref).hincrby key.to_s(depth), field, value
      end

      unless time_to_live.nil?
        db(connection_ref).expire key.to_s(depth), time_to_live
      end
    end

  end
end
