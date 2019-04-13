require 'inputs'
require 'date'

topic = Inputs.name('What is the name of the article?')

sanitized_topic = topic.downcase.gsub(/\s/, '-').gsub(/[^\w_-]/, '').squeeze('-')

time = Time.now

filename = "#{time.to_date}-#{sanitized_topic}.md"

template = <<-TEMPLATE.gsub(/^[\s\t]*/, '')
  ---
  layout: post
  title: "#{topic}"
  date: "#{time}"
  last_modified_at: "#{time}"
  categories: article
  ---
TEMPLATE

filepath = "_posts/article/#{filename}"
File.write(filepath, template)

puts "gvim #{filepath}"
