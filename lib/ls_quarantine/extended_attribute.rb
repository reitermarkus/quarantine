require 'date'
require 'extended_attributes'

module LSQuarantine
  # class for reading and writing 'com.apple.quarantine' extended attribute
  class ExtendedAttribute
    QUARANTINE_TYPES = {
      unopened:  0x0000,
      cancelled: 0x0020,
      opened:    0x0040,
    }.freeze

    ATTRIBUTE_REGEX = %r{
      (?<type>.*)\;
      (?<timestamp>.*)\;
      (?<agent_name>.*)\;
      (?<event_identifier>.*)
    }x

    def initialize(file)
      @file = ExtendedAttributes.new(File.expand_path(file))
    end

    def remove
      @file.remove('com.apple.quarantine')
    end

    def set(type, timestamp, agent: nil, event_id: nil)
      timestamp = datetime_to_hex_timestamp(timestamp)

      @file.set('com.apple.quarantine', "#{type};#{timestamp};#{agent};#{event_id}")
    end

    def get
      attribute_string = @file.get('com.apple.quarantine')

      return nil if attribute_string.nil?

      fields = attribute_string.match(ATTRIBUTE_REGEX)

      attribute = Hash[fields.names.zip(fields.captures)]

      attribute['timestamp'] = hex_timestamp_to_datetime(attribute['timestamp'])

      attribute
    end

    def datetime_to_hex_timestamp(date)
      date.strftime('%s').to_i.to_s(16)
    end

    def hex_timestamp_to_datetime(date)
      Time.at(date.to_i(16)).to_datetime
    end
  end
end
