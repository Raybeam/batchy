class CreateBatches < ActiveRecord::Migration
  def self.up
    create_table :batchy_batches, :force => true do |table|
      table.datetime  :started_at     # When the batch started
      table.datetime  :finished_at    # When the batch finished
      table.datetime  :expire_at      # When this batch should expire
      table.string    :state          # Current state of the batch
      table.text      :error          # Reason for failure (if there is one)
      table.string    :hostname       # Host the batch is running on
      table.integer   :pid            # Process ID of the current batch
      table.string    :name           # Name of the batch job
      table.string    :guid           # Field to be used for unique identification of the calling job
      table.integer   :batch_id       # Self-referential ID for identifying parent batches
      table.timestamps
    end

    add_index :batchy_batches, :guid
    add_index :batchy_batches, :state
  end

  def self.down
    drop_table :batchy_batches
  end
end