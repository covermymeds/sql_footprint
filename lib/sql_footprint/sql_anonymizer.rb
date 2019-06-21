module SqlFootprint
  class SqlAnonymizer
    @rules = {
      /\sIN\s\(.*\)/ => ' IN (values-redacted)'.freeze, # IN clauses
      /([\s\(])'.*'/ => "\\1'value-redacted'".freeze, # literal strings
      /N''.*''/ => "N''value-redacted''".freeze, # literal MSSQL strings
      /\s+(!=|=|<|>|<=|>=)\s+[0-9]+/ => ' \1 number-redacted'.freeze, # numbers
      /\s+VALUES\s+\(.*?\)/m => ' VALUES (values-redacted)'.freeze, # VALUES
    }

    def anonymize sql
      self.class.rules.reduce(sql) do |s, (regex, replacement)|
        s.gsub regex, replacement
      end
    end

    class << self
      attr_reader :rules

      def add_rule regex, replacement
        @rules[regex] = replacement
      end
    end
  end
end
