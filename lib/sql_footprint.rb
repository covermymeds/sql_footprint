require 'sql_footprint/version'
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
      @capture = true
      @lines   = Set.new
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
      return unless @capture
      @lines << strip_values(sql)
    end

    def strip_values sql
      sql = sql.gsub(/\[\[.*\]\]/, '')
      sql = strip_string_values(sql)
      sql = strip_integer_values(sql)
      strip_in_clause_values(sql)
    end

    def strip_in_clause_values sql
      sql.gsub(/\sIN\s\((.*)\)/) do |_match|
        ' IN (values-redacted)'
      end
    end

    def strip_integer_values sql
      sql.gsub(/\s\=\s([0-9]+)/) do |_match|
        ' = number-redacted'
      end
    end

    def strip_string_values sql
      sql.gsub(/\s'(.*)\'/) do |_match|
        " 'value-redacted'"
      end
    end
  end
end
