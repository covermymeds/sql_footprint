require 'sql_footprint/footprint_serializer'

module SqlFootprint
  class SqlCapturer
    attr_reader :statements, :database_name

    def initialize database_name
      @anonymizer   = SqlAnonymizer.new
      @filter       = SqlFilter.new
      @statements   = SqlStatements.new
      @database_name = database_name
    end

    def capture sql
      return unless @filter.capture?(sql)
      @statements.add @anonymizer.anonymize(sql)
    end

    def write
      File.write filename, serialized_statements
    end

    private

    def serialized_statements
      SqlFootprint::FootprintSerializer.new(statements).to_s
    end

    def filename
      "db/footprint.#{database_name.split('/').last}.sql"
    end
  end
end
