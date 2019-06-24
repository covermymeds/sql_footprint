require 'spec_helper'

describe SqlFootprint::SqlAnonymizer do
  let(:anonymizer) { described_class.new }

  it 'formats INSERT statements' do
    sql = 'INSERT INTO "widgets" ("created_at", "name") VALUES ' \
    "('2016-05-1 6 19:16:04.981048', 12345) RETURNING \"id\""
    expect(anonymizer.anonymize(sql)).to eq 'INSERT INTO "widgets" ' \
    '("created_at", "name") VALUES (values-redacted) RETURNING "id"'
  end

  it 'formats IN clauses' do
    sql = Widget.where(name: [SecureRandom.uuid, SecureRandom.uuid]).to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE "widgets"."name" IN (values-redacted)'
    )
  end

  it 'formats LIKE clauses' do
    sql = Widget.where(['name LIKE ?', SecureRandom.uuid]).to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE (name LIKE \'value-redacted\')'
    )
  end

  it 'formats numbers' do
    sql = Widget.where(quantity: rand(100)).to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE "widgets"."quantity" = number-redacted'
    )

    ['>', '<', '!=', '<=', '>='].each do |operator|
      sql = Widget.where(["quantity #{operator} ?", rand(100)]).to_sql
      expect(anonymizer.anonymize(sql)).to eq(
        'SELECT "widgets".* FROM "widgets" ' \
        "WHERE (quantity #{operator} number-redacted)"
      )
    end
  end

  it 'formats string literals' do
    sql = Widget.where(name: SecureRandom.uuid).to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE "widgets"."name" = \'value-redacted\''
    )
  end

  it 'formats string literals inside of LOWER' do
    sql = Widget.where("name = LOWER('whatever')").to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE (name = LOWER(\'value-redacted\'))'
    )
  end

  it 'formats unicode string literals for MSSQL' do
    sql = Widget.where("name = N''whatever''").to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE (name = N\'\'value-redacted\'\')'
    )
  end

  it 'handles multi-line VALUES' do
    sql = 'INSERT INTO "widgets" ("created_at", "name") VALUES ' \
    "('2016-05-1 6 19:16:04.981048', 'asdf\nasdf') RETURNING \"id\""
    expect(anonymizer.anonymize(sql)).to eq 'INSERT INTO "widgets" ' \
    '("created_at", "name") VALUES (values-redacted) RETURNING "id"'
  end

  context 'with a custom rule' do
    let(:redacted) { 'SELECT [redacted] AS [redacted]'.freeze }

    before do
      described_class.add_rule(/SELECT .+ AS .+/, redacted)
    end

    it 'formats as expected' do
      sql = 'SELECT some_thing AS other_thing'
      expect(anonymizer.anonymize(sql)).to eq(redacted)
    end
  end
end
