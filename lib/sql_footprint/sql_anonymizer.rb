module SqlFootprint
  class SqlAnonymizer
    GSUBS = {
      /\sIN\s\(.*\)/ => ' IN (values-redacted)'.freeze, # IN clauses
      /([\s\(])'.*'/ => "\\1'value-redacted'".freeze, # literal strings
      /N''.*''/ => "N''value-redacted''".freeze, # literal MSSQL strings
      /\s+(!=|=|<|>|<=|>=)\s+[0-9]+/ => ' \1 number-redacted', # numbers
      /\s+VALUES\s+\(.+\)/ => ' VALUES (values-redacted)', # VALUES
    }.freeze

    def anonymize sql
      GSUBS.reduce(sql) do |s, (regex, replacement)|
        s.gsub regex, replacement
      end
    end
  end
end
