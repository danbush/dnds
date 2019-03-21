#!/usr/bin/env ruby
$LOAD_PATH.unshift ("./gems/httparty-0.16.4/lib")
$LOAD_PATH.unshift ("./gems/multi_xml-0.6.0/lib")
$LOAD_PATH.unshift ("./gems/mime-types-3.2.2/lib")
$LOAD_PATH.unshift ("./gems/mime-types-data-3.2018.0812/lib")
$LOAD_PATH.unshift ("./gems/alfred-3_workflow-0.1.0/lib")

require 'httparty'
require 'alfred-3_workflow'

require 'open-uri'
require 'fileutils'
require 'json'

workflow = Alfred3::Workflow.new

query = ARGV[0]

FileUtils.rm_rf(Dir['./images/*'])

# Set some defaults
search_count = 0
search_results = ""
search_results_names = []

search_params = { :terms => query }

initial_search =
  HTTParty.get("https://roll20.net/compendium/compendium/globalsearch/dnd5e",
  :body => search_params
  )

search_results = JSON.parse(initial_search)

search_results_names = search_results.map { |h| h['value'] }.uniq
search_results_categories = search_results.map { |h| h['category'] }
search_results_pagenames = search_results.map { |h| h['pagename'] }.uniq
search_results_descriptions = []

categories_fixed = []
for cat in search_results_categories
  cat_fixed = cat.gsub(' ', '%20')
  categories_fixed << cat_fixed
end

i = 0
for item in search_results_pagenames
  item_fixed = item.gsub(' ', '%20').to_s

  category_fixed = ""
  if categories_fixed[i].to_s != ""
    category_fixed = categories_fixed[i].to_s + ":"
  end

  item_url = "https://app.roll20.net/compendium/dnd5e/" + category_fixed + item_fixed + ".json"
  item_search = 
    HTTParty.get(item_url)
  search_results_descriptions << item_search["content"].to_s.gsub("\t", "").gsub("\n", " ")

  subtitle_item = ""
  if item != search_results_names[i] 
    subtitle_item = " | " + item
  end

  subtitle_description = ""
  if search_results_descriptions[i] != nil 
    subtitle_description = " | " + search_results_descriptions[i]
  end

  workflow.result
      .title(search_results_names[i])
      .subtitle(search_results_categories[i].to_s + subtitle_item.to_s + subtitle_description.to_s)
      .arg(category_fixed + item_fixed)
  i += 1
  if i >= 5
    break
  end
end

if search_results_names[0] == nil
  workflow.result
      .title("Can't find any results. Maybe its in an additional book?")
      .subtitle("Hit enter to search online")
      .arg(query)
end

print workflow.output