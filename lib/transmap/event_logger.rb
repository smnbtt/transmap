module Transmap

  # Simple Event Logger that print the event with the payload data
  class EventLogger

    # Log event with payload data
    # @param name [String]
    # @param started [Time]
    # @param finished [Time]
    # @param unique_id [String]
    # @param data [Hash]
    def call(name, started, finished, unique_id, data)
      Transmap.logger.debug "#{name} -> #{data}"
    end

  end

end