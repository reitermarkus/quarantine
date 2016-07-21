#!/usr/bin/env ruby

$LOAD_PATH.unshift(File.expand_path(__dir__)) unless $LOAD_PATH.include?(File.expand_path(__dir__))

require 'ls_quarantine/database'
require 'ls_quarantine/extended_attribute'

module LSQuarantine
  module_function

  def add(file, database_path: nil)

  end

  def remove(file, database_path: nil)
    attribute = LSQuarantine::ExtendedAttribute.new(file)
    database  = LSQuarantine::Database.new(database_path)

    attribute_hash = attribute.get

    return true if attribute_hash.nil?

    uuid = attribute_hash['event_identifier']

    attribute.remove && database.delete(uuid)
  end
end

if __FILE__ == $PROGRAM_NAME
  require 'json'


  LSQuarantine.remove('/Users/Markus/Downloads/sheet07.pdf')
#  db = LSQuarantine::Database.new

  #puts db.uuid_exists?('00000000-0000-0000-0000-000000000000')
  #puts db.uuid_exists?('984B9284-B3F4-48A2-96F5-C52DBE485128')
  #puts
  #puts JSON.pretty_generate(db.get('984B9284-B3F4-48A2-96F5-C52DBE485128'))
  #puts
  #
  #xattr = LSQuarantine::ExtendedAttribute.new('~/Downloads/TextMate_2.0-beta.11.12.tbz')
  #
  #puts JSON.pretty_generate(xattr.get)
  #puts
  #puts db.generate_uuid
end
