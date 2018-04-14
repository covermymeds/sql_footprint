require 'spec_helper'

describe SqlFootprint do
  it 'has a version number' do
    expect(SqlFootprint::VERSION).not_to be nil
  end

  let(:statements) { described_class.capturers[':memory:'].statements }
  let(:footprint_file_name) { './db/footprint.:memory:.sql' }

  describe '.start' do
    before do
      described_class.start

      # Warmup so Widget.create just makes one new flavor of SQL
      Widget.first
      Cog.create!
    end

    it 'logs sql' do
      expect { Widget.create! }.to change { statements.count }.by(+1)
    end

    it 'formats inserts' do
      Widget.create!
      expect(statements.to_a).to include(
        'INSERT INTO "widgets" ("created_at", "updated_at") VALUES (values-redacted)'
      )
    end

    it 'appends the statement count by 1' do
      expect do
        Widget.where(name: SecureRandom.uuid, quantity: 1).last
      end.to change { statements.count }.by(+1)
    end

    it 'appends 1 sql statement' do
      matches = []
      Widget.where(name: SecureRandom.uuid, quantity: 1).last

      matches.push 'SELECT  "widgets".* FROM "widgets"'
      matches.push 'WHERE "widgets"."name" = ?'
      matches.push 'AND'
      matches.push 'widgets"."quantity" = ?'
      matches.push 'ORDER BY "widgets"."id" DESC'
      matches.push 'LIMIT ?'

      matches.each do |match|
        expect(statements.to_a.detect { |record| record.match match }).not_to be_nil
      end
    end

    it 'dedupes the same sql' do
      expect do
        Widget.create!
        Widget.create!
      end.to change { statements.count }.by(+1)
    end

    it 'works with joins' do
      Widget.joins(:cogs).where(name: SecureRandom.uuid).load
      expect(statements.to_a).to include(
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
      end.to change { statements.count }.by(+1)
      expect(statements.to_a.join).not_to include 'INSERT INTO \"widgets\"'
    end

    it 'does not write SHOW queries' do
      begin
        Widget.connection.execute("SHOW #{SecureRandom.uuid}")
      rescue
        "We don't care about the validity of the SQL" # rubocop
      end
      expect(statements.to_a.join).not_to include 'SHOW'
    end

    context 'with a custom rule' do
      let(:redacted) { '[redacted]'.freeze }

      before do
        described_class::SqlAnonymizer.add_rule(/SELECT .+ FROM .+/, redacted)
      end

      it 'formats as expected' do
        Widget.find_by(id: 9001)

        expect(statements.to_a).to include(redacted)
      end
    end
  end

  describe '.stop' do
    it 'writes the footprint' do
      described_class.start
      Widget.create!
      described_class.stop
      log = File.read(footprint_file_name)
      expect(log).to include('INSERT INTO')
    end

    it 'writes the sorted statements' do
      described_class.start
      Widget.create!
      Widget.first
      described_class.stop
      log = File.read(footprint_file_name)
      expect(statements.sort).to eq(log.split("\n").sort)
    end

    it 'removes old results' do
      described_class.start
      Widget.create!
      described_class.stop
      described_class.start
      Widget.last
      described_class.stop
      log = File.read(footprint_file_name)
      expect(log).not_to include('INSERT INTO')
    end
  end
end
