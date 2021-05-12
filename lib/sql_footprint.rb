require 'sql_footprint/version'
require 'sql_footprint/sql_anonymizer'
require 'sql_footprint/sql_capturer'
require 'sql_footprint/sql_filter'
require 'sql_footprint/sql_statements'
require 'active_support/notifications'

module SqlFootprint
  ActiveSupport::Notifications.subscribe('sql.active_record') do |_, _, _, _, payload|
    if @capture
      config = payload.fetch(:connection).instance_variable_get(:@config)
      database_name = config.fetch(:database)
      capturers[database_name].capture payload.fetch(:sql)
    end
  end

  class << self
    attr_reader :capturers

    def start
      @capture   = true
      @capturers = Hash.new do |hash, database_name|
        hash[database_name] = SqlCapturer.new(database_name)
      end
    end

    def stop
      @capture = false
      capturers.values.each(&:write)
    end

    def exclude
      @capture = false
      yield
    ensure
      @capture = true
    end
  end
end
