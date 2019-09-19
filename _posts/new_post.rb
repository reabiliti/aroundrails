# frozen_string_literal: true

require 'inputs'
require 'date'
require 'fileutils'

topic = Inputs.name('What is the name of the post?')
category = Inputs.name('What is the category of the post?')

dirname = "_posts/#{category}"
FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

sanitized_topic = topic.downcase.gsub(/\s/, '-').gsub(/[^\w_-]/, '').squeeze('-')

time = Time.now

filename = "#{time.to_date}-#{sanitized_topic}.md"

template = <<-TEMPLATE.gsub(/^[\s\t]*/, '')
  ---
  layout: post
  title: "#{topic}"
  date: "#{time}"
  last_modified_at: "#{time}"
  categories: #{category}
  ---
TEMPLATE

filepath = "#{dirname}/#{filename}"
File.write(filepath, template)

puts '---'.colorize(:yellow)
puts "created #{filepath}".colorize(:yellow)
puts '---'.colorize(:yellow)
