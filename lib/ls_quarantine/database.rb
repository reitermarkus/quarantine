require 'date'
require 'open3'
require 'securerandom'
require 'uri'

module LSQuarantine
  # class for reading from and inserting into Lauch Services database
  class Database
    DATABASE = '~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV2'.freeze

    TABLE = 'LSQuarantineEvent'.freeze

    FIELDS = %w[
      LSQuarantineEventIdentifier
      LSQuarantineTimeStamp
      LSQuarantineAgentBundleIdentifier
      LSQuarantineAgentName
      LSQuarantineDataURLString
      LSQuarantineSenderName
      LSQuarantineSenderAddress
      LSQuarantineTypeNumber
      LSQuarantineOriginTitle
      LSQuarantineOriginURLString
      LSQuarantineOriginAlias
    ].freeze

    TYPE_NUMBERS = {
      web_download:               0,
      other_download:             1,
      email_attachment:           2,
      instant_message_attachment: 3,
      calendar_event_attachment:  4,
      other_attachment:           5,
    }.freeze

    FIELDS_REGEX = %r{
      (?<event_identifier>.*)\|
      (?<time_stamp>.*)\|
      (?<agent_bundle_identifier>.*)\|
      (?<agent_name>.*)\|
      (?<data_url_string>.*)\|
      (?<sender_name>.*)\|
      (?<sender_address>.*)\|
      (?<type_number>.*)\|
      (?<origin_title>.*)\|
      (?<origin_url_string>.*)\|
      (?<origin_alias>.*)
    }x

    def initialize(path = nil)
      @path = File.expand_path(path || DATABASE)
    end

    def map_database_entry(k, v, nil_lambda, nil_replacement, timestamp_lambda, url_string_lambda)
      return nil_replacement if nil_lambda.call(v)

      case k
      when 'time_stamp'
        timestamp_lambda.call(v)
      when 'data_url_string', 'origin_url_string'
        url_string_lambda.call(v)
      else
        v
      end
    end

    def delete(uuid)
      database_query("DELETE " \
                     "FROM #{TABLE} " \
                     "WHERE LSQuarantineEventIdentifier == '#{uuid}' " \
                     "COLLATE NOCASE")

      !uuid_exists?(uuid)
    end

    def insert(database_entry)
      return false if uuid_exists?(database_entry['LSQuarantineEventIdentifier'])

      database_entry = database_entry.each_with_object({}) do |(k, v), h|
        h[k] = map_database_entry(k, v,
                                  ->(e) { e.nil? }, 'NULL',
                                  ->(d) { datetime_to_timestamp(d).to_s },
                                  ->(u) { u.to_s })
      end

      values = FIELDS.map { |field| "'#{database_entry.fetch(field, 'NULL')}'" }.join(',')

      database_query("INSERT INTO #{TABLE} VALUES(#{values});")[1].success?
    end

    def get(uuid)
      out, status = database_query("SELECT * " \
                                   "FROM #{TABLE} " \
                                   "WHERE LSQuarantineEventIdentifier == '#{uuid}' " \
                                   "COLLATE NOCASE") # case-insensitive

      return if out.empty? || !status.success?

      fields = out.match(FIELDS_REGEX)

      Hash[fields.names.zip(fields.captures)].each_with_object({}) { |(k, v), h|
        h[k] = map_database_entry(k, v,
                                  ->(e) { e.empty? }, nil,
                                  method(:timestamp_to_datetime),
                                  method(:URI))
      }
    end

    def generate_uuid
      loop do
        uuid = SecureRandom.uuid
        return uuid.upcase unless uuid_exists?(uuid)
      end
    end

    def uuid_exists?(uuid)
      !get(uuid).nil?
    end

    private

    def database_query(query)
      Open3.capture2('/usr/bin/sqlite3', @path, query)
    end

    TIME_STAMP_OFFSET = 978_307_200

    def datetime_to_timestamp(date)
      date.strftime('%s.%6N').to_f - TIME_STAMP_OFFSET
    end

    def timestamp_to_datetime(date)
      Time.at(date.to_f + TIME_STAMP_OFFSET).to_datetime
    end
  end
end
