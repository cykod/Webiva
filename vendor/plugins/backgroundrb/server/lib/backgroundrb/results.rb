module BackgrounDRb

  # The BackgrounDRb results module is used in two places. In the
  # regular worker to store and retrieve results from the results
  # worker. It is also used by the WorkerProxy when a worker is no
  # longer around and you want to access results through the MiddleMan.
  #
  # A limitation with this implementation, is that results are only
  # stored upon direct assignment to results[:key]. If you make
  # modifications to values, this will not be reflected:
  #
  #   results[:mykey] = []
  #   results[:mykey] << "adding to array"
  #
  # Instead you need to use a temporary array:
  #
  #   tmparray = []
  #   tmparray << "adding to array"
  #   tmparray << "adding more"
  #   results[:mykey] = tmparray
  #
  # Adding singleton behavior for the results values would make them
  # non-serializable. We already have that problem with the top level
  # results hash.
  module Results
    def init(jobkey)
      @jobkey = jobkey
      @results_worker ||= MiddleMan.instance.worker(:backgroundrb_results)
      self.merge!(stored)
    end

    def [](key)
      @results_worker.get_result(@jobkey, key)
    end

    def []=(key,value)
      result = { key => value }
      @results_worker.set_result(@jobkey, result)
      updated = @results_worker.get_worker_results(@jobkey)
      self.merge!(stored)
    end

    def stored
      @results_worker.get_worker_results(@jobkey)
    end

    def to_hash
      new_hash = {}
      self.each { |k,v| new_hash[k] = v }
      new_hash
    end
  end
end
