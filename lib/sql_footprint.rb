require 'sql_footprint/version'
require 'sql_footprint/sql_anonymizer'
require 'sql_footprint/sql_filter'
require 'set'
require 'active_support/notifications'

module SqlFootprint
  FILENAME = 'footprint.sql'.freeze
  NEWLINE = "\n".freeze

  ActiveSupport::Notifications.subscribe('sql.active_record') do |_, _, _, _, payload|
    capture payload.fetch(:sql)
  end

  class << self
    def start
      @anonymizer = SqlAnonymizer.new
      @filter     = SqlFilter.new
      @capture    = true
      @lines      = Set.new
    end

    def stop
      @capture = false
      File.write FILENAME, @lines.sort.join(NEWLINE)
    end

    def exclude
      @capture = false
      yield
    ensure
      @capture = true
    end

    def capture sql
      return unless @capture && @filter.capture?(sql)
      @lines << @anonymizer.anonymize(sql)
    end
  end
end
