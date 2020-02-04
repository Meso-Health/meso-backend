require 'io/console'

namespace :db do
  namespace :seed do
    desc 'Generate data for demo.'
    task demo_data: :environment do
      puts "\n>> Creating demo data in the #{Rails.env} database."
      load 'scripts/demo/generate_demo_data.rb'
      puts "\n>> Demo data created."
    end

    desc 'Generate Uganda demo data.'
    task uganda_data: :environment do
      puts "\n>> Creating Uganda demo data in the #{Rails.env} database."
      load 'scripts/uganda/generate_uganda_data.rb'
      puts "\n>> Uganda demo data created."
    end
  end
end
