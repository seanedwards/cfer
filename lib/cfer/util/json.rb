require 'rainbow'
require 'json'

module Cfer::Util::Json
  class << self

  QUOTE = '"'
  LBRACE = Rainbow('{').color :green
  RBRACE = Rainbow('}').color :green
  LBRACKET = Rainbow('[').color :green
  RBRACKET = Rainbow(']').color :green
  COLON = Rainbow(': ').color :green

  def format_json(item)
    case item
    when Hash
      format_hash(item)
    when Array
      format_array(item)
    when String
      format_string(item)
    when Numeric
      format_number(item)
    when TrueClass || FalseClass
      format_bool(item)
    else
      format_string(item.to_s)
    end
  end

  private
  def format_string(s)
    s.to_json
  end

  def format_number(n)
    n.to_json
  end

  def format_bool(b)
    b.to_json
  end

  def format_hash(h)
    LBRACE +
    if h.empty?
      ' '
    else
      "\n" +
      indent do
        h.map { |k, v| format_pair(k, v) }.join(",\n")
      end +
      "\n"
    end +
    RBRACE
  end

  def format_pair(k, v)
    QUOTE + Rainbow(k).color(:white) + QUOTE + COLON + format_json(v)
  end

  def format_array(a)
    LBRACKET +
    if a.empty?
      ' '
    else
      "\n" +
      indent do
        a.map { |i| format_json(i) }.join(",\n")
      end +
      "\n"
    end +
    RBRACKET
  end

  def indent
    str = yield
    "  " + str.gsub(/\n/, "\n  ")
  end

  end
end
