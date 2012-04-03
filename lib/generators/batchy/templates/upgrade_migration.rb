class AddBacktraceToBatchy < ActiveRecord::Migration
  def self.up
    add_column :batchy_batches, :backtrace, :text
  end

  def self.down
    remove_column :batchy_batches, :backtrace
  end
end