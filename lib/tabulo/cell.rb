require "unicode/display_width"

module Tabulo

  # Represents a single cell within the body of a {Table}.
  class Cell

    # @return the underlying value for this Cell
    attr_reader :value

    # @!visibility private
    def initialize(value:, formatter:, alignment:, width:, styler:, truncation_indicator:, padding_character:)
      @value = value
      @formatter = formatter
      @alignment = alignment
      @width = width
      @styler = styler
      @truncation_indicator = truncation_indicator
      @padding_character = padding_character
    end

    # @!visibility private
    def height
      subcells.size
    end

    # @!visibility private
    def padded_truncated_subcells(target_height, padding_amount_left, padding_amount_right)
      total_padding_amount = padding_amount_left + padding_amount_right
      truncated = (height > target_height)
      (0...target_height).map do |subcell_index|
        append_truncator = (truncated && (total_padding_amount != 0) && (subcell_index + 1 == target_height))
        padded_subcell(subcell_index, padding_amount_left, padding_amount_right, append_truncator)
      end
    end

    # @return [String] the content of the Cell, after applying the formatter for this Column (but
    #   without applying any wrapping or the styler).
    def formatted_content
      @formatted_content ||= @formatter.call(@value)
    end

    private

    def subcells
      @subcells ||= calculate_subcells
    end

    def padded_subcell(subcell_index, padding_amount_left, padding_amount_right, append_truncator)
      lpad = @padding_character * padding_amount_left
      rpad =
        if append_truncator
          styled_truncation_indicator + padding(padding_amount_right - 1)
        else
          padding(padding_amount_right)
        end
      inner = subcell_index < height ? subcells[subcell_index] : padding(@width)
      "#{lpad}#{inner}#{rpad}"
    end

    def padding(amount)
      @padding_character * amount
    end

    def styled_truncation_indicator
      @styler.call(@value, @truncation_indicator)
    end

    def calculate_subcells
      formatted_content.split($/, -1).flat_map do |substr|
        subsubcells, subsubcell, subsubcell_width = [], String.new(""), 0

        substr.scan(/\X/).each do |grapheme_cluster|
          grapheme_cluster_width = Unicode::DisplayWidth.of(grapheme_cluster)
          if subsubcell_width + grapheme_cluster_width > @width
            subsubcells << style_and_align_cell_content(subsubcell)
            subsubcell_width = 0
            subsubcell.clear
          end

          subsubcell << grapheme_cluster
          subsubcell_width += grapheme_cluster_width
        end

        subsubcells << style_and_align_cell_content(subsubcell)
      end
    end

    def style_and_align_cell_content(content)
      padding = [@width - Unicode::DisplayWidth.of(content), 0].max
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

      "#{' ' * left_padding}#{@styler.call(@value, content)}#{' ' * right_padding}"
    end

    def real_alignment
      return @alignment unless @alignment == :auto

      case @value
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
