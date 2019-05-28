#!/usr/bin/env ruby

# frozen_string_literal: true

require 'sqlite3'
require 'json'

# Class for auditing my campaign notes
class AuditCampaign
  attr_reader :db
  def initialize(in_file: Nil)
    @db = SQLite3::Database.new(ARGV[1])

    init_conn_type_map
    init_page_type_map

    File.open(in_file, 'r') do |f|
      campaign = JSON.parse(f.read)
      init_pages(campaign: campaign)
      init_conns(campaign: campaign)
    end
  end

  def init_conn_type_map
    @conn_type_map = {
      'fromid' => 'INTEGER',
      'toid' => 'INTEGER',
      'relationship' => 'TEXT'
    }.freeze
  end

  def init_conns(campaign:)
    build_table(
      name: 'connections',
      type_map: @conn_type_map,
      pkey: %w[fromid toid relationship]
    )
    populate_conns_table(campaign: campaign)
  end

  def populate_conns_table(campaign:)
    c = @conn_type_map
    @db.transaction do |t|
      t.prepare(
        gen_insert_statement(table_name: 'connections', type_map: c)
      ) do |stmt|
        campaign['conns'].each do |conn|
          stmt.execute(conn.select { |i, _| c.key? i })
        end
      end
    end
  end

  def init_page_type_map
    @page_type_map = {
      'concept' => 'TEXT',
      'id' => 'INTEGER',
      'briefSummary' => 'TEXT',
      'dateCreatedUnix' => 'INTEGER',
      'dateLastEditedUnix' => 'INTEGER',
      'description' => 'TEXT',
      'isSecret' => 'BOOLEAN',
      'name' => 'TEXT',
      'score' => 'INTEGER',
      'secrets' => 'TEXT',
      'uri' => 'TEXT'
    }.freeze
  end

  def init_pages(campaign:)
    build_table(
      name: 'pages',
      type_map: @page_type_map,
      pkey: %w[id]
    )
    populate_pages_table(campaign: campaign)
  end

  def populate_pages_table(campaign:)
    m = campaign
    c = @page_type_map
    @db.transaction do |t|
      t.prepare(
        gen_insert_statement(table_name: 'pages', type_map: c)
      ) { |stmt| m['pages'].each { |p| stmt.execute(get_page(pag: p)) } }
    end
  end

  def gen_create_statement(name:, type_map:, pkey:)
    cols = type_map.collect { |field, type| "#{field} #{type}" }
    constraints = ["PRIMARY KEY (#{pkey.join(', ')})"]
    "CREATE TABLE #{name} (" \
    + (cols + constraints).join(', ') \
    + ')'
  end

  def build_table(name:, type_map:, pkey:)
    @db.execute(
      gen_create_statement(
        name: name,
        type_map: type_map,
        pkey: pkey
      )
    )
  end

  def gen_insert_statement(table_name:, type_map:)
    columns = type_map.keys
    "insert into #{table_name} (" \
    + columns.join(', ') \
    + ') values (' \
    + (
        columns.map { |column| ":#{column}" }
      ).join(', ') + ')'
  end

  def get_page(pag:)
    (
      @page_type_map.keys.map do |column|
        [column, pag.key?(column) ? pag[column] : pag['page'][column]]
      end
    ).to_h
  end
end

AuditCampaign.new(in_file: ARGV[0])
