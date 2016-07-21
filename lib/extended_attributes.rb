#!/usr/bin/env ruby

require 'open3'

# class for reading and writing extended attributes
class ExtendedAttributes
  def initialize(file, follow_symlinks: false)
    @file = File.new(file)
    @follow_symlinks = follow_symlinks
  end

  def list
    out, status = command

    return nil unless status.success?
    return [] if out.empty?

    out.chomp.split(%r{\n})
  end

  def to_h
    lst = list

    return nil if lst.nil?

    list.each_with_object({}) do |attribute, hash|
      hash[attribute] = get(attribute)
    end
  end

  def set(name, content)
    command('-w', name, content)[1].success?
  end

  def get(name)
    out, status = command('-x', '-p', name)

    return nil unless status.success?

    # `xattr -x` outputs hex-string with line breaks and spaces
    [out.delete("\n\s")].pack('H*')
  end

  def remove(name)
    command('-d', name)
    !(list || []).include?(name)
  end

  def clear
    command('-c')[1].success?
  end

  private

  XATTR_EXECUTABLE = Open3.capture2('which', 'xattr')[0].chomp

  def command(*args)
    raise StandardError, 'xattr not installed.' if XATTR_EXECUTABLE.empty?

    args.unshift('-s') unless @follow_symlinks

    out, error, status = Open3.capture3(XATTR_EXECUTABLE, *args, @file.path)
    out = nil unless status.success? && error.empty?

    [out, status]
  end
end

if __FILE__ == $PROGRAM_NAME
  file = File.expand_path('~/Downloads/symlink')
  # file = File.realpath(file)

  file_with_attributes = ExtendedAttributes.new(file, follow_symlinks: true)

  print file_with_attributes.list, "\n"

  file_with_attributes.set('testattribute', 'SPAM')

  print file_with_attributes.get('testattribute'), "\n"

  print file_with_attributes.list, "\n"
  print file_with_attributes.to_h, "\n"

  puts file_with_attributes.clear

  print file_with_attributes.list, "\n"
  print file_with_attributes.to_h, "\n"
end
