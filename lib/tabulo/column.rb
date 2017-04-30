module Tabulo

  # @!visibility private
  class Column

    attr_accessor :width
    attr_reader :header, :label

    # @!visibility private
    def initialize(label:, header:, width:, align_header:, align_body:,
      formatter:, extractor:)

      @label = label
      @header = header
      @width = width
      @align_header = align_header
      @align_body = align_body
      @formatter = formatter
      @extractor = extractor
    end

    # @!visibility private
    def header_subcells
      infilled_subcells(@header, @align_header)
    end

    # @!visibility private
    def horizontal_rule
      Table::HORIZONTAL_RULE_CHARACTER * width
    end

    # @!visibility private
    def body_subcells(source)
      cell_datum = body_cell_value(source)
      formatted_content = @formatter.call(cell_datum)
      real_alignment = (@align_body || infer_alignment(cell_datum))
      infilled_subcells(formatted_content, real_alignment)
    end

    # @!visibility private
    def formatted_cell_content(source)
      @formatter.call(body_cell_value(source))
    end

    # @!visibility private
    def body_cell_value(source)
      @extractor.call(source)
    end

    private

    # @!visibility private
    def infilled_subcells(str, real_alignment)
      str.split($/, -1).flat_map do |substr|
        num_subsubcells = [1, (substr.length.to_f / width).ceil].max
        (0...num_subsubcells).map do |i|
          align_cell_content(substr.slice(i * width, width), real_alignment)
        end
      end
    end

    # @!visibility private
    def align_cell_content(content, real_alignment)
      padding = [@width - content.length, 0].max
      left_padding, right_padding =
        case real_alignment
        when :center
          half_padding = padding / 2
          [padding - half_padding, half_padding]
        when :left
          [0, padding]
        when :right
          [padding, 0]
        end

      "#{' ' * left_padding}#{content}#{' ' * right_padding}"
    end

    # @!visibility private
    def infer_alignment(cell_datum)
      case cell_datum
      when Numeric
        :right
      when TrueClass, FalseClass
        :center
      else
        :left
      end
    end
  end
end
