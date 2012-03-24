require 'rails/generators/migration'
require 'rails/generators/active_record/migration'

module Batchy
  class ActiveRecordGenerator
    include Rails::Generators::Migration
    extend ActiveRecord::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/create_batches.rb'
    end
  end
end