module Batchy
  # The StoppedError can be thrown in a batch's run to signify that
  # the batch was stopped, but not errored.
  #
  # An example use for this would be as part of a Data Recency Check -
  # which runs a SQL Statement to ensure the existance of data.
  # If data is not found, a StoppedError can be raised, which signifies
  # that it and any following batches were explicitly halted.
  class StoppedError < StandardError

  end
end
