module Tabulo

  class Row
    include Enumerable

    # @return the element of the {Table}'s underlying enumerable to which this {Row} corresponds
    attr_reader :source

    # @!visibility private
    def initialize(table, source, divider: false, header: :top)
      @table = table
      @source = source
      @divider = divider
      @header = header
    end

    # Calls the given block once for each {Cell} in the {Row}, passing that {Cell} as parameter.
    #
    # @example
    #   table = Tabulo::Table.new([1, 10], columns: %i(itself even?))
    #   row = table.first
    #   row.each do |cell|
    #     puts cell.value   # => 1,       => false
    #   end
    def each
      @table.column_registry.each do |_, column|
        yield column.body_cell(@source)
      end
    end

    # @return a String being an "ASCII" graphical representation of the {Row}, including
    #   any column headers or row divider that appear just above it in the {Table} (depending on where
    #   this Row is in the {Table}, and how the {Table} was configured with respect to header frequency
    #   and divider frequency).
    def to_s
      if @table.column_registry.any?
        @table.formatted_body_row(@source, header: @header, divider: @divider)
      else
        ""
      end
    end

    # @return a Hash representation of the {Row}, with column labels acting as keys and the {Cell}s the values.
    def to_h
      @table.column_registry.map { |label, column| [label, column.body_cell(@source)] }.to_h
    end
  end
end
