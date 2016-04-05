module SqlFootprint
  class SqlAnonymizer
    GSUBS = {
      /\s+IN\s+\(.*\)/ => ' IN (values-redacted)'.freeze, # IN clauses
      /\s+[0-9]+/ => ' number-redacted'.freeze, # numbers
      /\s+'.*'/ => " 'value-redacted'".freeze, # literal strings
    }.freeze

    def anonymize sql
      # subs => [key, value]
      GSUBS.reduce(sql) do |s, subs|
        s.gsub(subs.first, subs.last)
      end
    end
  end
end
