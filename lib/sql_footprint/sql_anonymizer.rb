module SqlFootprint
  class SqlAnonymizer
    GSUBS = {
      /\s+IN\s+\(.*\)/ => ' IN (values-redacted)'.freeze, # IN clauses
      /\s+[0-9]+/ => ' number-redacted'.freeze, # numbers
      /\s+'.*'/ => " 'value-redacted'".freeze, # literal strings
    }.freeze

    def anonymize sql
      GSUBS.reduce(sql) do |s, (regex, replacement)|
        s.gsub regex, replacement
      end
    end
  end
end
