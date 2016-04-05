require 'spec_helper'

describe SqlFootprint do
  it 'has a version number' do
    expect(SqlFootprint::VERSION).not_to be nil
  end

  describe '.start' do
    before do
      described_class.start

      # Warmup so Widget.create just makes one new flavor of SQL
      Widget.first
      Cog.create!
    end

    it 'logs sql' do
      expect { Widget.create! }.to change { described_class.lines.length }.by(+1)
    end

    it 'formats inserts' do
      Widget.create!
      expect(described_class.lines).to include(
        'INSERT INTO "widgets" ("created_at", "updated_at") VALUES (?, ?)'
      )
    end

    it 'formats selects' do
      Widget.where(name: SecureRandom.uuid, quantity: 1).last
      expect(described_class.lines).to include(
        'SELECT  "widgets".* FROM "widgets" ' \
        'WHERE "widgets"."name" = ? AND ' \
        '"widgets"."quantity" = ?  ' \
        'ORDER BY "widgets"."id" DESC LIMIT number-redacted'
      )
    end

    it 'dedupes the same sql' do
      expect do
        Widget.create!
        Widget.create!
      end.to change { described_class.lines.length }.by(+1)
    end

    it 'sorts the results' do
      Widget.where(name: SecureRandom.uuid, quantity: 1).last
      Widget.create!
      expect(described_class.lines.first).to include('INSERT INTO')
    end

    it 'works with joins' do
      Widget.joins(:cogs).where(name: SecureRandom.uuid).load
      expect(described_class.lines).to include(
        'SELECT "widgets".* FROM "widgets" ' \
        'INNER JOIN "cogs" ON "cogs"."widget_id" = "widgets"."id" ' \
        'WHERE "widgets"."name" = ?'
      )
    end

    it 'can exclude some statements' do
      expect do
        Widget.where(name: SecureRandom.hex).last
        widget = described_class.exclude { Widget.create! }
        expect(widget).to be_a(Widget)
      end.to change { described_class.lines.length }.by(+1)
      expect(described_class.lines.join).not_to include 'INSERT INTO \"widgets\"'
    end
  end

  describe '.stop' do
    it 'writes the footprint' do
      described_class.start
      Widget.create!
      described_class.stop
      log = File.read('footprint.sql')
      expect(log).to include('INSERT INTO')
    end

    it 'removes old results' do
      described_class.start
      Widget.create!
      described_class.stop
      described_class.start
      Widget.last
      described_class.stop
      log = File.read('footprint.sql')
      expect(log).not_to include('INSERT INTO')
    end
  end
end
