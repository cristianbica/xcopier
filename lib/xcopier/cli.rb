# frozen_string_literal: true

require "optparse"
require "active_support/core_ext/string/inflections"

module Xcopier
  class CLI
    def self.start(args)
      new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
      valid = parse
      return unless valid

      @options[:copier].new(**@options[:args]).run
    end

    def parse # rubocop:disable Metrics/CyclomaticComplexity,Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/MethodLength
      @options = { copier_name: @args.shift, args: {} }
      @options[:copier] = @options[:copier_name].classify.safe_constantize

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: xcopier copier_name [--arg1=value1 ...] [options]"

        opts.separator "\nCOPIER ARGUMENTS" if @options[:copier]&._arguments&.any?
        @options[:copier]&._arguments&.each do |arg|
          @options[:args][arg[:name]] = nil
          banner = "--#{arg[:name].to_s.humanize.parameterize}"
          banner += "=VALUE" if arg[:type] != :boolean
          help = "#{arg[:name]} copier argument"
          help << " (comma separated list)" if arg[:list]
          opts.on(banner, help) do |value|
            @options[:args][arg[:name]] = value
          end
        end

        opts.separator "\nOPTIONS"
        opts.on("-h", "--help", "Show help message") do
          @options[:help] = true
        end

        opts.on("-v", "--verbose", "Run verbosely") do
          @options[:verbose] = true
        end
      end
      parser.parse(@args)

      if @options[:help]
        puts parser
        return false
      end

      if @options[:copier].nil?
        puts "ERROR: Copier not found\n\n"
        puts parser
        return false
      end

      if @options[:args].values.any?(&:nil?)
        puts "ERROR: Missing argument values\n\n"
        puts parser
        return false
      end

      true
    end
  end
end
