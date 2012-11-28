begin

ActiveRecord::ConnectionAdapters::PostgreSQLAdapter

class ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  alias real_exec_no_cache_query exec_no_cache

  def exec_no_cache(*args)
    result = real_exec_no_cache_query(*args)
    unless result
      sleep 0.1
      ActiveRecord::Base.clear_active_connections!
      result = real_exec_no_cache_query(*args)
      raise "Unexpected threading problem with the DB driver!" unless result
    end
    result
  end
end

rescue NameError => e
  if e.message.include? "ActiveRecord::ConnectionAdapters::PostgreSQLAdapter"
    #do nothing, we just don't use Postgres. Devmode e.g.
  else
    raise e
  end
end