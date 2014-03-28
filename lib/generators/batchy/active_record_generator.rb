require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module Batchy
  class ActiveRecordGenerator < ActiveRecord::Generators::Base
    include Rails::Generators::Migration

    self.source_paths << File.join(File.dirname(__FILE__), 'templates')

    def create_migration_file
      migration_template 'migration.rb', 'db/migrate/create_batchy_batches.rb'
    end
  end
end
