#!/usr/bin/env ruby

require 'pdf-reader'
require 'pp'
require 'strscan'
require 'date'
require 'time'
require 'csv'



class PayslipReader
  attr_reader :path

  def initialize(path)
    @path = path
  end

  def reader
    @reader ||= PDF::Reader.new(path)
  end

  def text
    reader.pages.map(&:text).first.tr("\u00a0", ' ')
  end

  def this_period
    scanner = StringScanner.new(text)
    scanner.skip_until(/This Period/)
    scanner.skip(/\s+/)
    scanner.scan(/(\S+) +To +(\S+)/)
    from, to = scanner.captures
    {
      "From"=> from && Date.parse(from),
      "To"=> to && Date.parse(to)
    }
  end

  def payments_segment
    scanner = StringScanner.new(text)
    scanner.skip_until(/Payments.*Deductions/)
    scanner.skip_until(/$/)
    m = scanner.scan_until(/Message:/)
    m
  end

  def line_items
    return {} unless payments_segment
    scanner = StringScanner.new(payments_segment)
    line_items = {}
    begin
      scanner.skip(/\s*/m)
      scanner.scan(/^(?<label>(?:[\w@0-9,£\.%-]+ {1,2})*[\w@0-9,£\.%-]+) {3,}(?<amount>-?[0-9,]+\.[0-9]{2})/)
      if scanner.matched?
        label, value = scanner.captures
        line_items[label] = value
      end
    end while scanner.matched?
    line_items
  end

  def stats
    this_period.merge(line_items).merge("Filename" => path)
  end
end


unless ARGV.size > 0
  $stderr.puts "Usage: #{__FILE__} <payslip1.pdf>... [> output.csv]"
  exit 1
end

count = ARGV.size

i=1
stats = ARGV.map do |f|
  stats = PayslipReader.new(f).stats
  $stderr.printf "Parsed [%2d/%2d] => %2d keys : %s\n", i, count, stats.keys.size, f
  i+=1
  stats
end

all_keys = stats.map {|s| s.keys}.flatten.sort.uniq


keys_order = ["From",
 "To",
 "Pay Basic",
 "Pay Basic Arrears",
 "Unpaid Leave",
 "Pymt Non Consol Perform Bonus",
 "Rec and Ret Allow",
 "PAYE",
 "Alpha Pension",
 "NI A",
 "Total"]

keys_order_all = keys_order + (all_keys - keys_order)

csv_string = CSV.generate do |csv|
  csv << keys_order_all

  stats.each do |stat_record|
    csv << keys_order_all.map {|k| stat_record[k]}
  end
end

puts csv_string