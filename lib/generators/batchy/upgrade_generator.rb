require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

module Batchy
  class UpgradeGenerator < Rails::Generators::Base
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'upgrade_migration.rb', 'db/migrate/add_backtrace_to_batchy.rb'
    end
  end
end