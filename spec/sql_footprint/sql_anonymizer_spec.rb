require 'spec_helper'

describe SqlFootprint::SqlAnonymizer do
  let(:anonymizer) { described_class.new }

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
  end

  it 'formats string literals' do
    sql = Widget.where(name: SecureRandom.uuid).to_sql
    expect(anonymizer.anonymize(sql)).to eq(
      'SELECT "widgets".* FROM "widgets" ' \
      'WHERE "widgets"."name" = \'value-redacted\''
    )
  end
end
