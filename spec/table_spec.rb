require "spec_helper"

describe Tabulo::Table do

  around(:all) do |group|
    Tabulo::Deprecation.without_warnings { group.run }
  end

  let(:table) do
    Tabulo::Table.new(
      source,
      border: border,
      column_padding: column_padding,
      column_width: column_width,
      formatter: formatter,
      header_frequency: header_frequency,
      header_styler: header_styler,
      row_divider_frequency: row_divider_frequency,
      styler: styler,
      truncation_indicator: truncation_indicator,
      wrap_body_cells_to: wrap_body_cells_to,
      wrap_header_cells_to: wrap_header_cells_to,
    ) do |t|
      t.add_column("N") { |n| n }
      t.add_column("Doubled") { |n| n * 2 }
    end
  end

  let(:source) { 1..5 }
  let(:border) { :ascii }
  let(:column_padding) { nil }
  let(:column_width) { nil }
  let(:formatter) { :to_s.to_proc }
  let(:header_frequency) { :start }
  let(:header_styler) { nil }
  let(:row_divider_frequency) { nil }
  let(:styler) { nil }
  let(:truncation_indicator) { nil }
  let(:wrap_body_cells_to) { nil }
  let(:wrap_header_cells_to) { nil }

  it "is an Enumerable" do
    expect(table).to be_a(Enumerable)
    expect(table).to respond_to(:each)
    expect(table).to respond_to(:map)
    expect(table).to respond_to(:to_a)
  end

  describe "#initialize / #to_s" do
    describe "`columns` param" do
      it "accepts symbols corresponding to methods on the source objects" do
        expect(Tabulo::Table.new([1, 2, 3], :to_i, :to_f).to_s).to eq \
          %q(+--------------+--------------+
             |     to_i     |     to_f     |
             +--------------+--------------+
             |            1 |          1.0 |
             |            2 |          2.0 |
             |            3 |          3.0 |
             +--------------+--------------+).gsub(/^ +/, "")
      end

      it "raises Tabulo::InvalidColumnLabelError if symbols are not unique" do
        expect { Tabulo::Table.new([1, 2, 3], :to_i, :to_i) }.to \
          raise_error(Tabulo::InvalidColumnLabelError)
      end

      it "does not issue a deprecation warning" do
        expect(Tabulo::Deprecation).not_to receive(:warn)

        Tabulo::Table.new([1, 2, 3], :to_i, :to_s)
      end
    end

    describe "`header_frequency` param" do
      context "when table is initialized with `header_frequency: :start`" do
        let(:header_frequency) { :start }

        it "initializes a table displaying the formatted table with a header" do
          expect(table).to be_a(Tabulo::Table)
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `header_frequency: nil`" do
        let(:header_frequency) { nil }

        it "initializes a table displaying the formatted table without a header" do
          expect(table).to be_a(Tabulo::Table)
          expect(table.to_s).to eq \
            %q(|            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `header_frequency: <N>`" do
        let(:header_frequency) { 3 }
        let(:border) { :modern }

        it "initializes a table displaying the formatted table with header at start and then "\
          "before every Nth row thereafter" do
          expect(table.to_s).to eq \
            %q(┌──────────────┬──────────────┐
               │       N      │    Doubled   │
               ├──────────────┼──────────────┤
               │            1 │            2 │
               │            2 │            4 │
               │            3 │            6 │
               ├──────────────┼──────────────┤
               │       N      │    Doubled   │
               ├──────────────┼──────────────┤
               │            4 │            8 │
               │            5 │           10 │
               └──────────────┴──────────────┘).gsub(/^ +/, "")
        end
      end

      context "when the table doesn't have any columns" do
        specify "#to_s returns an empty string" do
          table = Tabulo::Table.new(0..10)
          expect(table.to_s).to eq("")
        end
      end
    end

    describe "`header_styler` param" do
      context "when passed `nil`" do
        let(:header_styler) { nil }

        it "does not apply any additional styling to the header text" do
          expect(table.to_s).to eq \
            %Q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a callable" do
        let(:header_styler) { -> (str) { "\033[31;1;4m#{str}\033[0m" } }

        it "applies additional styling to the header text of every column, without affecting the width "\
          "calculations" do
          expect(table.to_s).to eq \
            %Q(+--------------+--------------+
               |       \033[31;1;4mN\033[0m      |    \033[31;1;4mDoubled\033[0m   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end

        context "when a new column is added with `nil` passed to the `header_styler` option "\
          "of #add_column" do
          it "applies the same styling to the newly added column" do
            table.add_column("Trebled", header_styler: nil) { |n| n * 3 }
            expect(table.to_s).to eq \
              %Q(+--------------+--------------+--------------+
                 |       \033[31;1;4mN\033[0m      |    \033[31;1;4mDoubled\033[0m   |    \033[31;1;4mTrebled\033[0m   |
                 +--------------+--------------+--------------+
                 |            1 |            2 |            3 |
                 |            2 |            4 |            6 |
                 |            3 |            6 |            9 |
                 |            4 |            8 |           12 |
                 |            5 |           10 |           15 |
                 +--------------+--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when a new column is added with a different callable passed to the `header_styler` option "\
          "of #add_column" do
          it "applies the different styling to the newly added column only" do
            table.add_column( "Trebled", header_styler: -> (str) { "\033[32;4m#{str}\033[0m" }) { |n| n * 3 }
            expect(table.to_s).to eq \
              %Q(+--------------+--------------+--------------+
                 |       \033[31;1;4mN\033[0m      |    \033[31;1;4mDoubled\033[0m   |    \033[32;4mTrebled\033[0m   |
                 +--------------+--------------+--------------+
                 |            1 |            2 |            3 |
                 |            2 |            4 |            6 |
                 |            3 |            6 |            9 |
                 |            4 |            8 |           12 |
                 |            5 |           10 |           15 |
                 +--------------+--------------+--------------+).gsub(/^ +/, "")
          end
        end
      end
    end

    describe "`row_divider_frequency` param" do
      context "when table is initialized with `row_divider_frequency: nil`" do
        let(:row_divider_frequency) { nil }

        it "initializes a table displaying the formatted table without row dividers in the table body" do
          expect(table).to be_a(Tabulo::Table)
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with an integer passed to `row_divider_frequency`" do
        let(:row_divider_frequency) { 2 }

        context "when `header_frequency` is `:start`" do
          let(:header_frequency) { :start }

          it "initializes a table displaying a horizontal divider after every N rows, where N is the integer passed" do
            expect(table).to be_a(Tabulo::Table)
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 +--------------+--------------+
                 |            3 |            6 |
                 |            4 |            8 |
                 +--------------+--------------+
                 |            5 |           10 |
                 +--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when `header_frequency` is passed an integer" do
          let(:header_frequency) { 4 }

          it "initializes a table displaying a horizontal divider after every N rows, where N is the integer "\
            "passed, except when an header should be displayed, in which case the header is shown instead" do
            expect(table).to be_a(Tabulo::Table)
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 +--------------+--------------+
                 |            3 |            6 |
                 |            4 |            8 |
                 +--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            5 |           10 |
                 +--------------+--------------+).gsub(/^ +/, "")
          end
        end
      end
    end

    describe "`wrap_header_cells_to` param" do
      before(:each) { table.add_column("N" * 26, &:to_i) }

      context "when table is initialized with `wrap_header_cells_to: nil`" do
        let(:wrap_header_cells_to) { nil }

        it "wraps header cell contents as necessary if they exceed the column width" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   | NNNNNNNNNNNN |
               |              |              | NNNNNNNNNNNN |
               |              |              |      NN      |
               +--------------+--------------+--------------+
               |            1 |            2 |            1 |
               |            2 |            4 |            2 |
               |            3 |            6 |            3 |
               |            4 |            8 |            4 |
               |            5 |           10 |            5 |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `wrap_header_cells_to: <N>`" do
        context "when N rows are insufficient to accommodate the header content" do
          let(:wrap_header_cells_to) { 2 }

          it "truncates header cell contents to N subrows, instead of wrapping them indefinitely, "\
            "and shows a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+--------------+
                 |       N      |    Doubled   | NNNNNNNNNNNN |
                 |              |              | NNNNNNNNNNNN~|
                 +--------------+--------------+--------------+
                 |            1 |            2 |            1 |
                 |            2 |            4 |            2 |
                 |            3 |            6 |            3 |
                 |            4 |            8 |            4 |
                 |            5 |           10 |            5 |
                 +--------------+--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when N rows are insufficient to accommodate the header content and padding is 0" do
          let(:wrap_header_cells_to) { 2 }
          let(:column_padding) { 0 }

          it "truncates header cell contents to N subrows, instead of wrapping them indefinitely, "\
            "but does not show a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+------------+------------+------------+
                 |      N     |   Doubled  |NNNNNNNNNNNN|
                 |            |            |NNNNNNNNNNNN|
                 +------------+------------+------------+
                 |           1|           2|           1|
                 |           2|           4|           2|
                 |           3|           6|           3|
                 |           4|           8|           4|
                 |           5|          10|           5|
                 +------------+------------+------------+).gsub(/^ +/, "")
          end
        end

        context "when N rows are insufficient to accommodate the header content and padding > 1" do
          let(:wrap_header_cells_to) { 2 }
          let(:column_padding) { 2 }

          it "truncates header cell contents to N subrows, instead of wrapping them indefinitely, "\
            "and shows a single truncation indicator within the padded content" do
            expect(table.to_s).to eq \
              %q(+----------------+----------------+----------------+
                 |        N       |     Doubled    |  NNNNNNNNNNNN  |
                 |                |                |  NNNNNNNNNNNN~ |
                 +----------------+----------------+----------------+
                 |             1  |             2  |             1  |
                 |             2  |             4  |             2  |
                 |             3  |             6  |             3  |
                 |             4  |             8  |             4  |
                 |             5  |            10  |             5  |
                 +----------------+----------------+----------------+).gsub(/^ +/, "")
          end
        end

        context "when N rows are just insufficient to accommodate the header content" do
          let(:wrap_header_cells_to) { 3 }

          it "does not truncate the header cells and does not show a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+--------------+
                 |       N      |    Doubled   | NNNNNNNNNNNN |
                 |              |              | NNNNNNNNNNNN |
                 |              |              |      NN      |
                 +--------------+--------------+--------------+
                 |            1 |            2 |            1 |
                 |            2 |            4 |            2 |
                 |            3 |            6 |            3 |
                 |            4 |            8 |            4 |
                 |            5 |           10 |            5 |
                 +--------------+--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when N rows are more than sufficient to accommodate the header content" do
          let(:wrap_header_cells_to) { 4 }

          it 'only produces the number of "subrows" that are necessary to accommodate the contents, '\
            'and does not show a truncation indicator' do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+--------------+
                 |       N      |    Doubled   | NNNNNNNNNNNN |
                 |              |              | NNNNNNNNNNNN |
                 |              |              |      NN      |
                 +--------------+--------------+--------------+
                 |            1 |            2 |            1 |
                 |            2 |            4 |            2 |
                 |            3 |            6 |            3 |
                 |            4 |            8 |            4 |
                 |            5 |           10 |            5 |
                 +--------------+--------------+--------------+).gsub(/^ +/, "")
          end
        end
      end
    end

    describe "`wrap_body_cells_to` param" do
      let(:source) { [1, 2, 500_000_000_000] }
      let(:wrap_body_cells_to) { nil }

      context "when table is initialized with `wrap_body_cells_to: nil`" do
        let(:wrap_body_cells_to) { nil }

        it "wraps cell contents as necessary if they exceed the column width" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               | 500000000000 | 100000000000 |
               |              |            0 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when table is initialized with `wrap_body_cells_to: <N>`" do
        context "when N is insufficient to accommodate the cell content" do
          let(:wrap_body_cells_to) { 1 }

          it "truncates body cell contents to N subrows, instead of wrapping them indefinitely" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 | 500000000000 | 100000000000~|
                 +--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when N is just sufficient to accommodate the cell content" do
          let(:wrap_body_cells_to) { 2 }

          it "does not truncate the cell content, and does not show a truncation indicator" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 | 500000000000 | 100000000000 |
                 |              |            0 |
                 +--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when N is more than sufficient to accommodate the cell content" do
          let(:wrap_body_cells_to) { 3 }

          it "does not truncate the cell content, does not show a truncation indicator, and "\
            "produces only just enough subrows to accommodate the content" do
            expect(table.to_s).to eq \
              %q(+--------------+--------------+
                 |       N      |    Doubled   |
                 +--------------+--------------+
                 |            1 |            2 |
                 |            2 |            4 |
                 | 500000000000 | 100000000000 |
                 |              |            0 |
                 +--------------+--------------+).gsub(/^ +/, "")
          end
        end

        context "when N is more than sufficient to accommodate the cell content, and column_padding is > 1" do
          let(:wrap_body_cells_to) { 3 }
          let(:column_padding) { 2 }

          it "does not truncate the cell content, does not show a truncation indicator, and "\
            "produces only just enough subrows to accommodate the content, with column_padding respected" do
            expect(table.to_s).to eq \
              %q(+----------------+----------------+
                 |        N       |     Doubled    |
                 +----------------+----------------+
                 |             1  |             2  |
                 |             2  |             4  |
                 |  500000000000  |  100000000000  |
                 |                |             0  |
                 +----------------+----------------+).gsub(/^ +/, "")
          end
        end
      end
    end

    describe "`column_width` param" do
      context "if not specified or passed nil" do
        it "defaults to 12" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed an Integer" do
        let(:column_width) { 9 }

        it "causes all column widths to default to the given Integer, unless overridden for "\
          "particular columns" do
          table.add_column(:even?, width: 5)
          expect(table.to_s).to eq \
            %q(+-----------+-----------+-------+
               |     N     |  Doubled  | even? |
               +-----------+-----------+-------+
               |         1 |         2 | false |
               |         2 |         4 |  true |
               |         3 |         6 | false |
               |         4 |         8 |  true |
               |         5 |        10 | false |
               +-----------+-----------+-------+).gsub(/^ +/, "")
        end
      end
    end

    context "when there are multibyte characters in the headers or body cell contents" do
      it "calculates widths and aligns content correctly" do
        table = Tabulo::Table.new(1..3) do |t|
          t.add_column("Something") { |n| "很酷的时候" }
          t.add_column("很酷的时") { |n| n * 2 }
        end

        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             |   Something  |   很酷的时   |
             +--------------+--------------+
             | 很酷的时候   |            2 |
             | 很酷的时候   |            4 |
             | 很酷的时候   |            6 |
             +--------------+--------------+).gsub(/^ +/, "")
      end

      it "wraps content correctly" do
        table = Tabulo::Table.new(1..2) do |t|
          t.add_column("很\n酷") { |n| "很酷的时候很酷的时候" }
          t.add_column("很酷的时候很酷的时候很酷的时候") { |n| n * 2 }
        end

        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             |      很      | 很酷的时候很 |
             |      酷      | 酷的时候很酷 |
             |              |    的时候    |
             +--------------+--------------+
             | 很酷的时候很 |            2 |
             | 酷的时候     |              |
             | 很酷的时候很 |            4 |
             | 酷的时候     |              |
             +--------------+--------------+).gsub(/^ +/, "")
      end
    end

    context "when there are newlines in headers or body cell contents" do
      context "with unlimited wrapping" do
        it "respects newlines within header and cells" do
          table = Tabulo::Table.new(["Two\nlines", "\nInitial", "Final\n", "Multiple\nnew\nlines"]) do |t|
            t.add_column(:itself, header: "Firstpart\nsecondpart", width: 7) { |s| s }
            t.add_column(:length)
            t.add_column("Lines\nin\nheader", align_body: :right) { |s| s }
          end

          expect(table.to_s).to eq \
            %q(+---------+--------------+--------------+
               | Firstpa |    length    |     Lines    |
               |    rt   |              |      in      |
               | secondp |              |    header    |
               |   art   |              |              |
               +---------+--------------+--------------+
               | Two     |            9 |          Two |
               | lines   |              |        lines |
               |         |            8 |              |
               | Initial |              |      Initial |
               | Final   |            6 |        Final |
               |         |              |              |
               | Multipl |           18 |     Multiple |
               | e       |              |          new |
               | new     |              |        lines |
               | lines   |              |              |
               +---------+--------------+--------------+).gsub(/^ +/, "")

        end
      end

      context "with truncation" do
        it "accounts for newlines within header and cells" do
          table = Tabulo::Table.new(["Two\nlines", "\nInitial", "Final\n", "Multiple\nnew\nlines"],
            wrap_header_cells_to: 2, wrap_body_cells_to: 1) do |t|
            t.add_column(:itself) { |s| s }
            t.add_column(:length)
            t.add_column("Lines\nin\nheader", align_body: :right) { |s| s }
          end

          expect(table.to_s).to eq \
            %q(+--------------+--------------+--------------+
               |    itself    |    length    |     Lines    |
               |              |              |      in     ~|
               +--------------+--------------+--------------+
               | Two         ~|            9 |          Two~|
               |             ~|            8 |             ~|
               | Final       ~|            6 |        Final~|
               | Multiple    ~|           18 |     Multiple~|
               +--------------+--------------+--------------+).gsub(/^ +/, "")
        end
      end
    end

    describe "`truncation_indicator` param" do
      let(:table) do
        Tabulo::Table.new(
          source,
          wrap_header_cells_to: 1,
          wrap_body_cells_to: 1,
          truncation_indicator: truncation_indicator
        ) do |t|
          t.add_column("N") { |n| n }
          t.add_column("AAAAAAAAAAAAAAAAAAAA") { |n| n * 2 }
        end
      end
      let(:source) { [400000000000000000, 400000000000000001] }

      context "when passed nil" do
        let(:truncation_indicator) { nil }

        it "determines the character used to indicate that a cell's content has been truncated, "\
          "defaulting to '~'" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      | AAAAAAAAAAAA~|
               +--------------+--------------+
               | 400000000000~| 800000000000~|
               | 400000000000~| 800000000000~|
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a non-nil character" do
        let(:truncation_indicator) { "*" }

        it "causes the character used for indicating that a cell's content has been truncated, to be that"\
          "character" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      | AAAAAAAAAAAA*|
               +--------------+--------------+
               | 400000000000*| 800000000000*|
               | 400000000000*| 800000000000*|
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed something other than nil or a single-character String" do
        subject do
          Tabulo::Table.new(source, truncation_indicator: truncation_indicator)
        end

        context "when passed an empty string" do
          let(:truncation_indicator) { "" }

          it "raises a Tabulo::InvalidTruncationIndicatorError" do
            expect { subject }.to raise_error(Tabulo::InvalidTruncationIndicatorError)
          end
        end

        context "when passed an string longer than one character" do
          let(:truncation_indicator) { "!!" }

          it "raises a Tabulo::InvalidTruncationIndicatorError" do
            expect { subject }.to raise_error(Tabulo::InvalidTruncationIndicatorError)
          end
        end

        context "when passed something other than nil or a String" do
          let(:truncation_indicator) { 1 }

          it "raises a Tabulo::InvalidTruncationIndicatorError" do
            expect { subject }.to raise_error(Tabulo::InvalidTruncationIndicatorError)
          end
        end
      end
    end

    describe "`column_padding` param" do
      context "by default" do
        it "determines the amount of padding on either side of each column to be 1" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               |            4 |            8 |
               |            5 |           10 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a number greater than 1" do
        let(:column_padding) { 2 }

        it "determines the amount of padding on either side of each column to be that number" do
          expect(table.to_s).to eq \
            %q(+----------------+----------------+
               |        N       |     Doubled    |
               +----------------+----------------+
               |             1  |             2  |
               |             2  |             4  |
               |             3  |             6  |
               |             4  |             8  |
               |             5  |            10  |
               +----------------+----------------+).gsub(/^ +/, "")
        end
      end

      context "when passed 0" do
        let(:column_padding) { 0 }

        it "causes there to be no padding on either side of each column" do
          expect(table.to_s).to eq \
            %q(+------------+------------+
               |      N     |   Doubled  |
               +------------+------------+
               |           1|           2|
               |           2|           4|
               |           3|           6|
               |           4|           8|
               |           5|          10|
               +------------+------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a two-element array" do
        let(:column_padding) { [1, 2] }

        it "configures the left and right padding with the first and second values of the array, respectively" do
          expect(table.to_s).to eq \
            %q(+---------------+---------------+
               |       N       |    Doubled    |
               +---------------+---------------+
               |            1  |            2  |
               |            2  |            4  |
               |            3  |            6  |
               |            4  |            8  |
               |            5  |           10  |
               +---------------+---------------+).gsub(/^ +/, "")
        end
      end
    end

    describe "`formatter` param" do
      let(:formatter) { -> (n) { "%.2f" % n } }

      it "determines the formatter used on column values within the table body, unless overridden by the "\
        "`formatter` option on #add_column" do
        table.add_column("Halved", formatter: :to_s.to_proc) { |n| n / 2.0 }
        table.add_column("Quartered") { |n| n / 4.0 }
        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+--------------+
             |       N      |    Doubled   |    Halved    |   Quartered  |
             +--------------+--------------+--------------+--------------+
             |         1.00 |         2.00 |          0.5 |         0.25 |
             |         2.00 |         4.00 |          1.0 |         0.50 |
             |         3.00 |         6.00 |          1.5 |         0.75 |
             |         4.00 |         8.00 |          2.0 |         1.00 |
             |         5.00 |        10.00 |          2.5 |         1.25 |
             +--------------+--------------+--------------+--------------+).gsub(/^ +/, "")
      end
    end

    describe "`align_header` param" do
      let(:table) do
        Tabulo::Table.new(
          source,
          align_header: :left,
          border: border,
          column_padding: column_padding,
          column_width: column_width,
          header_frequency: header_frequency,
          truncation_indicator: truncation_indicator,
          wrap_body_cells_to: wrap_body_cells_to,
          wrap_header_cells_to: wrap_header_cells_to,
        ) do |t|
          t.add_column("N") { |n| n }
          t.add_column("Doubled") { |n| n * 2 }
        end
      end

      it "sets the default header alignment for columns in the table" do
        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             | N            | Doubled      |
             +--------------+--------------+
             |            1 |            2 |
             |            2 |            4 |
             |            3 |            6 |
             |            4 |            8 |
             |            5 |           10 |
             +--------------+--------------+).gsub(/^ +/, "")
      end

      it "sets a default header alignment that can be overriden via #add_column" do
        table.add_column(:even?, header: "Even?", align_header: :right)

        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             | N            | Doubled      |        Even? |
             +--------------+--------------+--------------+
             |            1 |            2 |     false    |
             |            2 |            4 |     true     |
             |            3 |            6 |     false    |
             |            4 |            8 |     true     |
             |            5 |           10 |     false    |
             +--------------+--------------+--------------+).gsub(/^ +/, "")
      end
    end

    describe "`align_body` param" do
      let(:table) do
        Tabulo::Table.new(
          source,
          align_body: :left,
          border: border,
          column_padding: column_padding,
          column_width: column_width,
          header_frequency: header_frequency,
          truncation_indicator: truncation_indicator,
          wrap_body_cells_to: wrap_body_cells_to,
          wrap_header_cells_to: wrap_header_cells_to,
        ) do |t|
          t.add_column("N") { |n| n }
          t.add_column("Doubled") { |n| n * 2 }
        end
      end

      it "sets the default body cell alignment for columns in the table" do
        expect(table.to_s).to eq \
          %q(+--------------+--------------+
             |       N      |    Doubled   |
             +--------------+--------------+
             | 1            | 2            |
             | 2            | 4            |
             | 3            | 6            |
             | 4            | 8            |
             | 5            | 10           |
             +--------------+--------------+).gsub(/^ +/, "")
      end

      it "sets a default body cell alignment that can be overriden via #add_column" do
        table.add_column(:even?, header: "Even?", align_body: :right)

        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             |       N      |    Doubled   |     Even?    |
             +--------------+--------------+--------------+
             | 1            | 2            |        false |
             | 2            | 4            |         true |
             | 3            | 6            |        false |
             | 4            | 8            |         true |
             | 5            | 10           |        false |
             +--------------+--------------+--------------+).gsub(/^ +/, "")
      end
    end

    describe "`border` param" do
      let(:table) { Tabulo::Table.new([1, 2, 3], :to_i, :to_f, border: border) }

      context "when passed `nil`" do
        let(:border) { nil }

        it "produces a table with borders consisting of ASCII characters" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |     to_i     |     to_f     |
               +--------------+--------------+
               |            1 |          1.0 |
               |            2 |          2.0 |
               |            3 |          3.0 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed `:ascii`" do
        let(:border) { :ascii }

        it "produces a table with borders consisting of ASCII characters" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |     to_i     |     to_f     |
               +--------------+--------------+
               |            1 |          1.0 |
               |            2 |          2.0 |
               |            3 |          3.0 |
               +--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed `:classic`" do
        let(:border) { :classic }

        it "produces a table with borders consisting of ASCII characters, with no bottom border" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+
               |     to_i     |     to_f     |
               +--------------+--------------+
               |            1 |          1.0 |
               |            2 |          2.0 |
               |            3 |          3.0 |).gsub(/^ +/, "")
        end
      end

      context "when passed `:reduced_ascii`" do
        let(:border) { :reduced_ascii }

        it "produces a table with borders consisting of ASCII characters, with no vertical lines" do
          expect(table.to_s).to eq([
              "-------------- --------------",
              "     to_i           to_f     ",
              "-------------- --------------",
              "            1            1.0 ",
              "            2            2.0 ",
              "            3            3.0 ",
              "-------------- --------------",
          ].join($/))
        end
      end

      context "when passed `:reduced_modern`" do
        let(:border) { :reduced_modern }

        it "produces a table with borders consisting of ASCII characters, with no vertical lines" do
          expect(table.to_s).to eq([
              "────────────── ──────────────",
              "     to_i           to_f     ",
              "────────────── ──────────────",
              "            1            1.0 ",
              "            2            2.0 ",
              "            3            3.0 ",
              "────────────── ──────────────",
          ].join($/))
        end
      end

      context "when passed `:markdown`" do
        let(:border) { :markdown }

        it "produces a Markdown table" do
          expect(table.to_s).to eq \
            %q(|     to_i     |     to_f     |
               |--------------|--------------|
               |            1 |          1.0 |
               |            2 |          2.0 |
               |            3 |          3.0 |).gsub(/^ +/, "")
        end
      end

      context "when passed `:modern`" do
        let(:border) { :modern }

        it 'produces a table with smoothly joined "Unicode" borders' do
          expect(table.to_s).to eq \
            %q(┌──────────────┬──────────────┐
               │     to_i     │     to_f     │
               ├──────────────┼──────────────┤
               │            1 │          1.0 │
               │            2 │          2.0 │
               │            3 │          3.0 │
               └──────────────┴──────────────┘).gsub(/^ +/, "")
        end
      end

      context "when passed `:blank`" do
        let(:border) { :blank }

        it "produces a table with no external or internal borders" do
          # Using joined array of strings to work around editor auto-trimming trailing whitespace.
          expect(table.to_s).to eq([
            "     to_i          to_f     ",
            "            1           1.0 ",
            "            2           2.0 ",
            "            3           3.0 "
          ].join($/))
        end
      end

      context "when passed an unrecognized value" do
        let(:border) { :fence }

        it "raises an InvalidBorderError" do
          expect { table.to_s }.to raise_error(Tabulo::InvalidBorderError)
        end
      end
    end

    describe "`border_styler` param" do
      let(:table) do
        Tabulo::Table.new(1..2, border: border, border_styler: -> (str) { "\033[31m#{str}\033[0m" }) do |t|
          t.add_column(:itself) { |n| n }
          t.add_column(:even?)
        end
      end

      let(:border) { :ascii }

      it "styles border, divider and intersection characters without affecting width calculations" do
        expect(table.to_s).to eq \
          %Q(\033[31m+--------------+--------------+\033[0m
             \033[31m|\033[0m    itself    \033[31m|\033[0m     even?    \033[31m|\033[0m
             \033[31m+--------------+--------------+\033[0m
             \033[31m|\033[0m            1 \033[31m|\033[0m     false    \033[31m|\033[0m
             \033[31m|\033[0m            2 \033[31m|\033[0m     true     \033[31m|\033[0m
             \033[31m+--------------+--------------+\033[0m).gsub(/^ +/, "")
      end

      context "when the border type lacks some horizontal lines" do
        let(:border) { :classic }

        it "does not apply styling to missing lines" do
          expect(table.to_s).to eq \
            %Q(\033[31m+--------------+--------------+\033[0m
               \033[31m|\033[0m    itself    \033[31m|\033[0m     even?    \033[31m|\033[0m
               \033[31m+--------------+--------------+\033[0m
               \033[31m|\033[0m            1 \033[31m|\033[0m     false    \033[31m|\033[0m
               \033[31m|\033[0m            2 \033[31m|\033[0m     true     \033[31m|\033[0m).gsub(/^ +/, "")
        end
      end
    end
  end

  describe "#add_column" do
    it "adds to the table's columns" do
      expect { table.add_column(:even?) }.to change { table.column_registry.count }.by(1)
    end

    describe "`header` param" do
      it "sets the column header, independently of the `label` argument" do
        table.add_column(:even?, header: "Armadillo")
        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             |       N      |    Doubled   |   Armadillo  |
             +--------------+--------------+--------------+
             |            1 |            2 |     false    |
             |            2 |            4 |     true     |
             |            3 |            6 |     false    |
             |            4 |            8 |     true     |
             |            5 |           10 |     false    |
             +--------------+--------------+--------------+).gsub(/^ +/, "")
      end
    end

    describe "column alignment" do
      let(:column_width) { 8 }

      it "by default, aligns text left, booleans center and numbers right, with header text centered" do
        table.add_column(:to_s)
        table.add_column(:even?)
        table.add_column(:to_f)

        expect(table.to_s).to eq \
          %q(+----------+----------+----------+----------+----------+
             |     N    |  Doubled |   to_s   |   even?  |   to_f   |
             +----------+----------+----------+----------+----------+
             |        1 |        2 | 1        |   false  |      1.0 |
             |        2 |        4 | 2        |   true   |      2.0 |
             |        3 |        6 | 3        |   false  |      3.0 |
             |        4 |        8 | 4        |   true   |      4.0 |
             |        5 |       10 | 5        |   false  |      5.0 |
             +----------+----------+----------+----------+----------+).gsub(/^ +/, "")
      end

      context "when passed `align_header` and `align_body` are passed :left, :center or :right" do
        it "aligns header and body accordingly, overriding the default alignments" do
          table.add_column(:to_s, align_header: :left, align_body: :center)
          table.add_column(:even?, align_header: :left, align_body: :right)
          table.add_column(:to_f, align_header: :right, align_body: :left)
          expect(table.to_s).to eq \
            %q(+----------+----------+----------+----------+----------+
               |     N    |  Doubled | to_s     | even?    |     to_f |
               +----------+----------+----------+----------+----------+
               |        1 |        2 |     1    |    false | 1.0      |
               |        2 |        4 |     2    |     true | 2.0      |
               |        3 |        6 |     3    |    false | 3.0      |
               |        4 |        8 |     4    |     true | 4.0      |
               |        5 |       10 |     5    |    false | 5.0      |
               +----------+----------+----------+----------+----------+).gsub(/^ +/, "")
        end
      end
    end

    describe "`before` param" do
      subject do
        table.add_column("Trebled", before: before) { |n| n * 3 }
      end

      context "when passed `nil`" do
        let(:before) { nil }

        it "inserts a column to the right of all other columns" do
          expect { subject }.to change(table, :to_s).to \
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   |    Trebled   |
               +--------------+--------------+--------------+
               |            1 |            2 |            3 |
               |            2 |            4 |            6 |
               |            3 |            6 |            9 |
               |            4 |            8 |           12 |
               |            5 |           10 |           15 |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a Symbol corresponding to the label of an existing column" do
        let(:before) { :Doubled }

        it "inserts a column to the left of the column with this label" do
          expect { subject }.to change(table, :to_s).to \
            %q(+--------------+--------------+--------------+
               |       N      |    Trebled   |    Doubled   |
               +--------------+--------------+--------------+
               |            1 |            3 |            2 |
               |            2 |            6 |            4 |
               |            3 |            9 |            6 |
               |            4 |           12 |            8 |
               |            5 |           15 |           10 |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a String corresponding to the label of an existing column" do
        let(:before) { :Doubled }

        it "inserts a column to the left of the column with this label" do
          expect { subject }.to change(table, :to_s).to \
            %q(+--------------+--------------+--------------+
               |       N      |    Trebled   |    Doubled   |
               +--------------+--------------+--------------+
               |            1 |            3 |            2 |
               |            2 |            6 |            4 |
               |            3 |            9 |            6 |
               |            4 |           12 |            8 |
               |            5 |           15 |           10 |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when passed a Symbol not corresponding to the label of any existing column" do
        let(:before) { :Quadrupled }

        it "raises an InvalidColumnLabelError" do
          expect { subject }.to raise_error(Tabulo::InvalidColumnLabelError)
        end
      end
    end

    describe "`width` param" do
      it "fixes the column width at the passed value (not including padding), overriding the default "\
        "column width for the table" do
        table.add_column("Trebled", width: 16) { |n| n * 3 }
        expect(table.to_s).to eq \
          %q(+--------------+--------------+------------------+
             |       N      |    Doubled   |      Trebled     |
             +--------------+--------------+------------------+
             |            1 |            2 |                3 |
             |            2 |            4 |                6 |
             |            3 |            6 |                9 |
             |            4 |            8 |               12 |
             |            5 |           10 |               15 |
             +--------------+--------------+------------------+).gsub(/^ +/, "")
      end
    end

    describe "`formatter` param" do
      it "formats the cell value for display, without changing the underlying cell value or its default alignment" do
        table.add_column("Trebled", formatter: -> (val) { "%.2f" % val }) do |n|
          n * 3
        end
        expect(table.to_s).to eq \
          %q(+--------------+--------------+--------------+
             |       N      |    Doubled   |    Trebled   |
             +--------------+--------------+--------------+
             |            1 |            2 |         3.00 |
             |            2 |            4 |         6.00 |
             |            3 |            6 |         9.00 |
             |            4 |            8 |        12.00 |
             |            5 |           10 |        15.00 |
             +--------------+--------------+--------------+).gsub(/^ +/, "")
        top_right_body_cell = table.first.to_a.last
        expect(top_right_body_cell.value).to eq(3)
        expect(top_right_body_cell.value).to be_a(Integer)
      end
    end

    describe "`styler` param" do
      it "styles the cell value by calling the styler on the underlying cell value and the formatted value, "\
        "without changing the underlying cell value's default alignment, and without affecting column width "\
        "calculations" do
        table.add_column(
          "Trebled",
          formatter: -> (val) { "%.2f" % val },
          styler: -> (val, str) { val == 6 ? "\033[31;1;4m#{str}\033[0m" : str }
        ) do |n|
          n * 3
        end

        expect(table.to_s).to eq \
          %Q(+--------------+--------------+--------------+
             |       N      |    Doubled   |    Trebled   |
             +--------------+--------------+--------------+
             |            1 |            2 |         3.00 |
             |            2 |            4 |         \033[31;1;4m6.00\033[0m |
             |            3 |            6 |         9.00 |
             |            4 |            8 |        12.00 |
             |            5 |           10 |        15.00 |
             +--------------+--------------+--------------+).gsub(/^ +/, "")
        top_right_body_cell = table.first.to_a.last
        expect(top_right_body_cell.value).to eq(3)
        expect(top_right_body_cell.value).to be_a(Integer)
      end

      it "applies the same styling to the truncation indicator as to the cell content" do
        table = Tabulo::Table.new(%w[hello yes], wrap_body_cells_to: 1)
        table.add_column(:itself, width: 3, styler: -> (val, str) { "\033[31m#{str}\033[0m" }) { |n| n }

        expect(table.to_s).to eq \
          %Q(+-----+
             | its |
             | elf |
             +-----+
             | \033[31mhel\033[0m\033[31m~\033[0m|
             | \033[31myes\033[0m |
             +-----+).gsub(/^ +/, "")
      end

      it "applies styling separately to each part of the wrapped cell content that's on its own line" do
        table = Tabulo::Table.new(%w[hello yes])
        table.add_column(:itself, width: 3, styler: -> (val, str) { "\033[31m#{str}\033[0m" }) { |n| n }

        expect(table.to_s).to eq \
          %Q(+-----+
             | its |
             | elf |
             +-----+
             | \033[31mhel\033[0m |
             | \033[31mlo\033[0m  |
             | \033[31myes\033[0m |
             +-----+).gsub(/^ +/, "")
      end
    end

    describe "`header_styler` param" do
      it "styles the header cell content by calling the header_styler on the header text without "\
        "affecting width calculations" do
        table.add_column("Trebled", header_styler: -> (str) { "\033[31;1;4m#{str}\033[0m" }) { |n| n * 3 }

        expect(table.to_s).to eq \
          %Q(+--------------+--------------+--------------+
             |       N      |    Doubled   |    \033[31;1;4mTrebled\033[0m   |
             +--------------+--------------+--------------+
             |            1 |            2 |            3 |
             |            2 |            4 |            6 |
             |            3 |            6 |            9 |
             |            4 |            8 |           12 |
             |            5 |           10 |           15 |
             +--------------+--------------+--------------+).gsub(/^ +/, "")
      end

      it "applies the same styling to the truncation indicator as to the cell content" do
        table = Tabulo::Table.new(%w[hello yes], wrap_header_cells_to: 1)
        table.add_column("itself", width: 3, header_styler: -> (str) { "\033[31m#{str}\033[0m" }) { |n| n }

        expect(table.to_s).to eq \
          %Q(+-----+
             | \033[31mits\033[0m\033[31m~\033[0m|
             +-----+
             | hel |
             | lo  |
             | yes |
             +-----+).gsub(/^ +/, "")
      end

      it "applies styling separately to each part of the wrapped header cell content that's on its own line" do
        table = Tabulo::Table.new(%w[hello yes])
        table.add_column("itself", width: 3, header_styler: -> (str) { "\033[31m#{str}\033[0m" }) { |n| n }

        expect(table.to_s).to eq \
          %Q(+-----+
             | \033[31mits\033[0m |
             | \033[31melf\033[0m |
             +-----+
             | hel |
             | lo  |
             | yes |
             +-----+).gsub(/^ +/, "")
      end
    end

    describe "`extractor` param" do
      context "when provided" do
        let(:table) do
          Tabulo::Table.new(1..5) do |t|
            t.add_column("N") { |s| s }
            t.add_column("x 2") do |n|
              n * 2
            end
            t.add_column("x 3", &(proc { |n| n * 3 }))
            t.add_column("x 4", &(-> (n) { n * 4 }))
            t.add_column("x 5") { |n| n * 5 }
          end
        end

        it "accepts a block or other callable, with which it calculates the cell value" do
          expect(table.to_s).to eq \
            %q(+--------------+--------------+--------------+--------------+--------------+
               |       N      |      x 2     |      x 3     |      x 4     |      x 5     |
               +--------------+--------------+--------------+--------------+--------------+
               |            1 |            2 |            3 |            4 |            5 |
               |            2 |            4 |            6 |            8 |           10 |
               |            3 |            6 |            9 |           12 |           15 |
               |            4 |            8 |           12 |           16 |           20 |
               |            5 |           10 |           15 |           20 |           25 |
               +--------------+--------------+--------------+--------------+--------------+).gsub(/^ +/, "")
        end
      end

      context "when not provided" do
        let(:table) do
          Tabulo::Table.new(1..5) do |t|
            t.add_column(:even?)
          end
        end

        specify "the first argument is called as a method on each source item to derive the cell value" do
          expect(table.to_s).to eq \
            %q(+--------------+
               |     even?    |
               +--------------+
               |     false    |
               |     true     |
               |     false    |
               |     true     |
               |     false    |
               +--------------+).gsub(/^ +/, "")
        end
      end
    end

    context "when the column label is not unique (even if one was passed a String and the other a Symbol)" do
      it "raises Tabulo::InvalidColumnLabelError" do
        table.add_column("abc") { |n| n * 3 }
        expect { table.add_column(:abc) { |n| n * 4 } }.to raise_error(Tabulo::InvalidColumnLabelError)
      end
    end

    context "when column label differs from that of an existing column only in regards to case" do
      it "does not raise an exception" do
        table.add_column("abc") { |n| n * 3 }
        expect { table.add_column("Abc") { |n| n * 4 } }.not_to raise_error
      end
    end
  end

  describe "#remove_column" do
    subject { table.remove_column(label) }

    let(:table) do
      Tabulo::Table.new(1..3) do |t|
        t.add_column(:N) { |n| n }
        t.add_column("Doubled") { |n| n * 2 }
        t.add_column(3) { |n| "three" }
      end
    end

    context "when passed the label of an existing column that was initialized with a string label" do
      context "when the passed label is a string that's equal to the label the column was initialized with" do
        let(:label) { "Doubled" }

        it { is_expected.to eq(true) }

        it "removes that column from the table" do
          expect { subject }.to change { table.to_s }.from(
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   |       3      |
               +--------------+--------------+--------------+
               |            1 |            2 | three        |
               |            2 |            4 | three        |
               |            3 |            6 | three        |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
          ).to(
            %q(+--------------+--------------+
               |       N      |       3      |
               +--------------+--------------+
               |            1 | three        |
               |            2 | three        |
               |            3 | three        |
               +--------------+--------------+).gsub(/^ +/, "")
          )
        end
      end

      context "when the passed is a Symbol version of the label the column was initialized with" do
        let(:label) { :Doubled }

        it { is_expected.to eq(true) }

        it "removes that column from the table" do
          expect { subject }.to change { table.to_s }.from(
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   |       3      |
               +--------------+--------------+--------------+
               |            1 |            2 | three        |
               |            2 |            4 | three        |
               |            3 |            6 | three        |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
          ).to(
            %q(+--------------+--------------+
               |       N      |       3      |
               +--------------+--------------+
               |            1 | three        |
               |            2 | three        |
               |            3 | three        |
               +--------------+--------------+).gsub(/^ +/, "")
          )
        end
      end
    end

    context "when passed the label of an existing column that was initialized with a Symbol label" do
      context "when the passed label is a Symbol that's equal to the label the column was initialized with" do
        let(:label) { :N }

        it { is_expected.to eq(true) }

        it "removes that column from the table" do
          expect { subject }.to change { table.to_s }.from(
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   |       3      |
               +--------------+--------------+--------------+
               |            1 |            2 | three        |
               |            2 |            4 | three        |
               |            3 |            6 | three        |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
          ).to(
            %q(+--------------+--------------+
               |    Doubled   |       3      |
               +--------------+--------------+
               |            2 | three        |
               |            4 | three        |
               |            6 | three        |
               +--------------+--------------+).gsub(/^ +/, "")
          )
        end
      end

      context "when the passed is a string version of the label the column was initialized with" do
        let(:label) { "N" }

        it { is_expected.to eq(true) }

        it "removes that column from the table" do
          expect { subject }.to change { table.to_s }.from(
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   |       3      |
               +--------------+--------------+--------------+
               |            1 |            2 | three        |
               |            2 |            4 | three        |
               |            3 |            6 | three        |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
          ).to(
            %q(+--------------+--------------+
               |    Doubled   |       3      |
               +--------------+--------------+
               |            2 | three        |
               |            4 | three        |
               |            6 | three        |
               +--------------+--------------+).gsub(/^ +/, "")
          )
        end
      end
    end

    context "when passed the label of an existing column that was initalized with an integer label" do
      context "when the passed label is an integer that's equal to the label the column was initialized with" do
        let(:label) { 3 }

        it { is_expected.to eq(true) }

        it "removes that column from the table" do
          expect { subject }.to change { table.to_s }.from(
            %q(+--------------+--------------+--------------+
               |       N      |    Doubled   |       3      |
               +--------------+--------------+--------------+
               |            1 |            2 | three        |
               |            2 |            4 | three        |
               |            3 |            6 | three        |
               +--------------+--------------+--------------+).gsub(/^ +/, "")
          ).to(
            %q(+--------------+--------------+
               |       N      |    Doubled   |
               +--------------+--------------+
               |            1 |            2 |
               |            2 |            4 |
               |            3 |            6 |
               +--------------+--------------+).gsub(/^ +/, "")
          )
        end
      end

      context "when the passed label is a string version of the label the column was initialized with" do
        let(:label) { "3" }

        it { is_expected.to eq(false) }

        it "does not removes the column from the table" do
          expect { subject }.not_to change { table.to_s }
        end
      end
    end

    context "when passed a string label that doesn't correspond to any of the existing column's labels" do
      let(:label) { "banana" }

      it { is_expected.to eq(false) }

      it "does not removes the column from the table" do
        expect { subject }.not_to change { table.to_s }
      end
    end

    context "when passed an integer label that doesn't correspond to any of the existing column's labels" do
      let(:label) { 1 }

      it { is_expected.to eq(false) }

      it "does not removes the column from the table" do
        expect { subject }.not_to change { table.to_s }
      end
    end

    context "when it causes the only remaining column of the table to be removed" do
      let(:table) do
        Tabulo::Table.new(1..3) do |t|
          t.add_column("Doubled") { |n| n * 2 }
        end
      end
      let(:label) { "Doubled" }

      it { is_expected.to be_truthy }

      it "changes the table to an empty table that is rendered as a empty string" do
        expect { subject }.to change { table.to_s }.to("")
      end
    end
  end

  describe "#each" do
    it "iterates once for each row of the table's source data" do
      i = 0
      table.each do |row|
        i += 1
      end
      expect(i).to eq(5)
    end

    it "iterates over instances of Tabulo::Row" do
      table.each do |row|
        expect(row).to be_a(Tabulo::Row)
      end
    end
  end

  describe "#formatted_header" do
    it "returns a string representing a header row for the table" do
      expect(table.formatted_header).to eq("|       N      |    Doubled   |") end
  end

  describe "#horizontal_rule" do
    let(:border) { :modern }

    it "returns a horizontal line made up of the horizontal rule character, and appropriately placed "\
      "corner characters, of an appropriate width for the table, suitable for the printing at the passed position" do
      aggregate_failures do
        expect(table.horizontal_rule(:top)).to    eq("┌──────────────┬──────────────┐")
        expect(table.horizontal_rule(:middle)).to eq("├──────────────┼──────────────┤")
        expect(table.horizontal_rule(:bottom)).to eq("└──────────────┴──────────────┘")
        expect(table.horizontal_rule).to          eq("└──────────────┴──────────────┘")
      end
    end
  end

  describe "#pack" do
    let(:column_width) { 8 }

    before(:each) do
      table.add_column(:to_s)
      table.add_column("Is it\neven?") { |n| n.even? }
      table.add_column("dec", formatter: -> (n) { "%.#{n}f" % n }) { |n| n }
      table.add_column("word\nyep", width: 5) { |n| "w" * n * 2 }
      table.add_column("cool") { |n| "two\nlines" if n == 3 }
    end

    it "returns the Table itself" do
      expect(table.pack(max_table_width: [nil, 64, 47].sample)).to eq(table)
    end

    it "does not issue a deprecation warning" do
      expect(Tabulo::Deprecation).not_to receive(:warn)

      table.pack
    end

    context "when `max_table_width` is nil" do
      it "expands or contracts the column widths of the table as necessary so that they just "\
        "accommodate their header and formatted body contents without wrapping (assuming "\
        "source data is constant), except insofar as is required to honour newlines within "\
        "the cell content", :aggregate_failures do

        # Check that it adjusts column widths by shrinking
        expect { table.pack }.to change(table, :to_s).from(
          %q(+----------+----------+----------+----------+----------+-------+----------+
             |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
             |          |          |          |   even?  |          |  yep  |          |
             +----------+----------+----------+----------+----------+-------+----------+
             |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
             |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
             |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
             |          |          |          |          |          | w     | lines    |
             |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
             |          |          |          |          |          | www   |          |
             |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
             |          |          |          |          |          | wwwww |          |
             +----------+----------+----------+----------+----------+-------+----------+).gsub(/^ +/, "")

        ).to(
          %q(+---+---------+------+-------+---------+------------+-------+
             | N | Doubled | to_s | Is it |   dec   |    word    |  cool |
             |   |         |      | even? |         |     yep    |       |
             +---+---------+------+-------+---------+------------+-------+
             | 1 |       2 | 1    | false |     1.0 | ww         |       |
             | 2 |       4 | 2    |  true |    2.00 | wwww       |       |
             | 3 |       6 | 3    | false |   3.000 | wwwwww     | two   |
             |   |         |      |       |         |            | lines |
             | 4 |       8 | 4    |  true |  4.0000 | wwwwwwww   |       |
             | 5 |      10 | 5    | false | 5.00000 | wwwwwwwwww |       |
             +---+---------+------+-------+---------+------------+-------+).gsub(/^ +/, "")
        )

        # Let's do a quick check to make sure that it will also expand the total table width if required.
        small_table = Tabulo::Table.new(%w(hello goodbye), column_width: 3) do |t|
          t.add_column("itself") { |s| s }
        end
        expect { small_table.pack }.to change(small_table, :to_s).from(
          %q(+-----+
             | its |
             | elf |
             +-----+
             | hel |
             | lo  |
             | goo |
             | dby |
             | e   |
             +-----+).gsub(/^ +/, "")
        ).to(
          %q(+---------+
             |  itself |
             +---------+
             | hello   |
             | goodbye |
             +---------+).gsub(/^ +/, "")
        )
      end
    end

    context "when `max_table_width` is nil" do
      context "when column_padding is > 1" do
        let(:column_padding) { 2 }

        it "expands or contracts the column widths of the table as necessary so that they just "\
          "accommodate their header and formatted body contents without wrapping (assuming "\
          "source data is constant), inclusive of additional padding, except insofar as is "\
          "required to honour newlines within the cell content" do

          # Check that it adjusts column widths by shrinking
          expect { table.pack }.to change(table, :to_s).to(
            %q(+-----+-----------+--------+---------+-----------+--------------+---------+
               |  N  |  Doubled  |  to_s  |  Is it  |    dec    |     word     |   cool  |
               |     |           |        |  even?  |           |      yep     |         |
               +-----+-----------+--------+---------+-----------+--------------+---------+
               |  1  |        2  |  1     |  false  |      1.0  |  ww          |         |
               |  2  |        4  |  2     |   true  |     2.00  |  wwww        |         |
               |  3  |        6  |  3     |  false  |    3.000  |  wwwwww      |  two    |
               |     |           |        |         |           |              |  lines  |
               |  4  |        8  |  4     |   true  |   4.0000  |  wwwwwwww    |         |
               |  5  |       10  |  5     |  false  |  5.00000  |  wwwwwwwwww  |         |
               +-----+-----------+--------+---------+-----------+--------------+---------+).gsub(/^ +/, "")
          )
        end
      end
    end

    context "when `max_table_width` is passed an integer (assuming source data is constant)" do
      context "when `max_table_width` is wider than the existing table width" do
        it "amends the column widths of the table so that they just accommodate their header and "\
          "formatted body contents without wrapping (assuming source data is constant), except "\
          "insofar as is required to honour newlines within the cell content " do

          expect { table.pack(max_table_width: 64) }.to change(table, :to_s).from(
            %q(+----------+----------+----------+----------+----------+-------+----------+
               |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
               |          |          |          |   even?  |          |  yep  |          |
               +----------+----------+----------+----------+----------+-------+----------+
               |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
               |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
               |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
               |          |          |          |          |          | w     | lines    |
               |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
               |          |          |          |          |          | www   |          |
               |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
               |          |          |          |          |          | wwwww |          |
               +----------+----------+----------+----------+----------+-------+----------+).gsub(/^ +/, "")

          ).to(
            %q(+---+---------+------+-------+---------+------------+-------+
               | N | Doubled | to_s | Is it |   dec   |    word    |  cool |
               |   |         |      | even? |         |     yep    |       |
               +---+---------+------+-------+---------+------------+-------+
               | 1 |       2 | 1    | false |     1.0 | ww         |       |
               | 2 |       4 | 2    |  true |    2.00 | wwww       |       |
               | 3 |       6 | 3    | false |   3.000 | wwwwww     | two   |
               |   |         |      |       |         |            | lines |
               | 4 |       8 | 4    |  true |  4.0000 | wwwwwwww   |       |
               | 5 |      10 | 5    | false | 5.00000 | wwwwwwwwww |       |
               +---+---------+------+-------+---------+------------+-------+).gsub(/^ +/, "")

          )
        end
      end

      context "when `max_table_width` is too narrow to accommodate the packed columns" do
        it "amends the column widths of the table so that they just accommodate their header and "\
          "formatted body contents (assuming source data is constant) (except insofar as it required "\
          "to honour newlines within existing cell content), except that width is progressively "\
          "removed from the widest column until the table fits the passed width" do

          expect { table.pack(max_table_width: 55) }.to change(table, :to_s).from(
            %q(+----------+----------+----------+----------+----------+-------+----------+
               |     N    |  Doubled |   to_s   |   Is it  |    dec   |  word |   cool   |
               |          |          |          |   even?  |          |  yep  |          |
               +----------+----------+----------+----------+----------+-------+----------+
               |        1 |        2 | 1        |   false  |      1.0 | ww    |          |
               |        2 |        4 | 2        |   true   |     2.00 | wwww  |          |
               |        3 |        6 | 3        |   false  |    3.000 | wwwww | two      |
               |          |          |          |          |          | w     | lines    |
               |        4 |        8 | 4        |   true   |   4.0000 | wwwww |          |
               |          |          |          |          |          | www   |          |
               |        5 |       10 | 5        |   false  |  5.00000 | wwwww |          |
               |          |          |          |          |          | wwwww |          |
               +----------+----------+----------+----------+----------+-------+----------+).gsub(/^ +/, "")
          ).to(
            %q(+---+--------+------+-------+--------+--------+-------+
               | N | Double | to_s | Is it |   dec  |  word  |  cool |
               |   |    d   |      | even? |        |   yep  |       |
               +---+--------+------+-------+--------+--------+-------+
               | 1 |      2 | 1    | false |    1.0 | ww     |       |
               | 2 |      4 | 2    |  true |   2.00 | wwww   |       |
               | 3 |      6 | 3    | false |  3.000 | wwwwww | two   |
               |   |        |      |       |        |        | lines |
               | 4 |      8 | 4    |  true | 4.0000 | wwwwww |       |
               |   |        |      |       |        | ww     |       |
               | 5 |     10 | 5    | false | 5.0000 | wwwwww |       |
               |   |        |      |       |      0 | wwww   |       |
               +---+--------+------+-------+--------+--------+-------+).gsub(/^ +/, "")
          )
        end

        context "when column_padding is > 1" do
          let(:column_padding) { 2 }

          it "amends the column widths of the table so that they just accommodate their header and "\
            "formatted body contents (assuming source data is constant) (except insofar as it required "\
            "to honour newlines within existing cell content), including additional padding, except "\
            "that width is progressively removed from the widest column until the table fits the "\
            "passed width" do

            expect { table.pack(max_table_width: 69) }.to change(table, :to_s).from(
              %q(+------------+------------+------------+------------+------------+---------+------------+
                 |      N     |   Doubled  |    to_s    |    Is it   |     dec    |   word  |    cool    |
                 |            |            |            |    even?   |            |   yep   |            |
                 +------------+------------+------------+------------+------------+---------+------------+
                 |         1  |         2  |  1         |    false   |       1.0  |  ww     |            |
                 |         2  |         4  |  2         |    true    |      2.00  |  wwww   |            |
                 |         3  |         6  |  3         |    false   |     3.000  |  wwwww  |  two       |
                 |            |            |            |            |            |  w      |  lines     |
                 |         4  |         8  |  4         |    true    |    4.0000  |  wwwww  |            |
                 |            |            |            |            |            |  www    |            |
                 |         5  |        10  |  5         |    false   |   5.00000  |  wwwww  |            |
                 |            |            |            |            |            |  wwwww  |            |
                 +------------+------------+------------+------------+------------+---------+------------+).gsub(/^ +/, "")
            ).to(
              %q(+-----+----------+--------+---------+----------+----------+---------+
                 |  N  |  Double  |  to_s  |  Is it  |    dec   |   word   |   cool  |
                 |     |     d    |        |  even?  |          |    yep   |         |
                 +-----+----------+--------+---------+----------+----------+---------+
                 |  1  |       2  |  1     |  false  |     1.0  |  ww      |         |
                 |  2  |       4  |  2     |   true  |    2.00  |  wwww    |         |
                 |  3  |       6  |  3     |  false  |   3.000  |  wwwwww  |  two    |
                 |     |          |        |         |          |          |  lines  |
                 |  4  |       8  |  4     |   true  |  4.0000  |  wwwwww  |         |
                 |     |          |        |         |          |  ww      |         |
                 |  5  |      10  |  5     |  false  |  5.0000  |  wwwwww  |         |
                 |     |          |        |         |       0  |  wwww    |         |
                 +-----+----------+--------+---------+----------+----------+---------+).gsub(/^ +/, "")
            )
          end
        end

        context "when column_padding is 0" do
          let(:column_padding) { 0 }

          it "amends the column widths of the table so that they just accommodate their header and "\
            "formatted body contents (assuming source data is constant) (except insofar as it required "\
            "to honour newlines within existing cell content), with no padding, except "\
            "that width is progressively removed from the widest column until the table fits the "\
            "passed width" do

            expect { table.pack(max_table_width: 41) }.to change(table, :to_s).from(
              %q(+--------+--------+--------+--------+--------+-----+--------+
                 |    N   | Doubled|  to_s  |  Is it |   dec  | word|  cool  |
                 |        |        |        |  even? |        | yep |        |
                 +--------+--------+--------+--------+--------+-----+--------+
                 |       1|       2|1       |  false |     1.0|ww   |        |
                 |       2|       4|2       |  true  |    2.00|wwww |        |
                 |       3|       6|3       |  false |   3.000|wwwww|two     |
                 |        |        |        |        |        |w    |lines   |
                 |       4|       8|4       |  true  |  4.0000|wwwww|        |
                 |        |        |        |        |        |www  |        |
                 |       5|      10|5       |  false | 5.00000|wwwww|        |
                 |        |        |        |        |        |wwwww|        |
                 +--------+--------+--------+--------+--------+-----+--------+).gsub(/^ +/, "")
            ).to(
              %q(+-+------+----+-----+------+------+-----+
                 |N|Double|to_s|Is it|  dec | word | cool|
                 | |   d  |    |even?|      |  yep |     |
                 +-+------+----+-----+------+------+-----+
                 |1|     2|1   |false|   1.0|ww    |     |
                 |2|     4|2   | true|  2.00|wwww  |     |
                 |3|     6|3   |false| 3.000|wwwwww|two  |
                 | |      |    |     |      |      |lines|
                 |4|     8|4   | true|4.0000|wwwwww|     |
                 | |      |    |     |      |ww    |     |
                 |5|    10|5   |false|5.0000|wwwwww|     |
                 | |      |    |     |     0|wwww  |     |
                 +-+------+----+-----+------+------+-----+).gsub(/^ +/, "")
            )
          end
        end
      end

      context "when `max_table_width` is very small" do
        it "only reduces column widths to the extent that there is at least a character's width "\
          "available in each column for content, plus one character of padding on either side" do
          table = Tabulo::Table.new(%w(hi there)) do |t|
            t.add_column(:itself) { |s| s }
            t.add_column(:length)
          end
          table.pack(max_table_width: 3)

          expect(table.to_s).to eq \
            %q(+---+---+
               | i | l |
               | t | e |
               | s | n |
               | e | g |
               | l | t |
               | f | h |
               +---+---+
               | h | 2 |
               | i |   |
               | t | 5 |
               | h |   |
               | e |   |
               | r |   |
               | e |   |
               +---+---+).gsub(/^ +/, "")
        end
      end

      context "when `max_table_width` is passed :auto" do
        it "caps the table width at the screen width, as returned by TTY::Screen.width" do
          allow(TTY::Screen).to receive(:width).and_return(13)
          table = Tabulo::Table.new(1..3, :to_i, :to_f)
          table.pack(max_table_width: :auto)
          expect(table.to_s).to eq \
            %q(+-----+-----+
               | to_ | to_ |
               |  i  |  f  |
               +-----+-----+
               |   1 | 1.0 |
               |   2 | 2.0 |
               |   3 | 3.0 |
               +-----+-----+).gsub(/^ +/, "")
        end
      end
    end
  end

  describe "#transpose" do
    let(:source) { 1..3 }
    let(:column_width) { 9 }

    it "returns another table" do
      result = table.transpose
      expect(result).not_to be(table)
      expect(result).to be_a(Tabulo::Table)
    end

    it "returns a table that's transposed relative to the original one, with config options overridably "\
      "inherited from the original table, other than for the left-most column's width and alignment, which are "\
      "determined automatically, and default to left-aligned, respectively" do
      aggregate_failures do
        expect(table.transpose.to_s).to eq \
          %q(+---------+-----------+-----------+-----------+
             |         |     1     |     2     |     3     |
             +---------+-----------+-----------+-----------+
             |       N |         1 |         2 |         3 |
             | Doubled |         2 |         4 |         6 |
             +---------+-----------+-----------+-----------+).gsub(/^ +/, "")

        expect(table.transpose(column_width: 3).to_s).to eq \
          %q(+---------+-----+-----+-----+
             |         |  1  |  2  |  3  |
             +---------+-----+-----+-----+
             |       N |   1 |   2 |   3 |
             | Doubled |   2 |   4 |   6 |
             +---------+-----+-----+-----+).gsub(/^ +/, "")
      end
    end

    it "accepts options for determining the header, width and alignment of the left-most column of the "\
      "transposed table" do
      expect(table.transpose(column_width: 3, field_names_width: 20, field_names_header: "FIELDS",
        field_names_header_alignment: :center, field_names_body_alignment: :left).to_s).to eq \
        %q(+----------------------+-----+-----+-----+
           |        FIELDS        |  1  |  2  |  3  |
           +----------------------+-----+-----+-----+
           | N                    |   1 |   2 |   3 |
           | Doubled              |   2 |   4 |   6 |
           +----------------------+-----+-----+-----+).gsub(/^ +/, "")
    end

    it "right-aligns the left-hand column of the new table by default" do
      expect(table.transpose(column_width: 3, field_names_width: 20, field_names_header: "FIELDS").to_s).to eq \
        %q(+----------------------+-----+-----+-----+
           |               FIELDS |  1  |  2  |  3  |
           +----------------------+-----+-----+-----+
           |                    N |   1 |   2 |   3 |
           |              Doubled |   2 |   4 |   6 |
           +----------------------+-----+-----+-----+).gsub(/^ +/, "")
    end

    it "accepts a :headers option, allowing the caller to customize the column headers, "\
      "(other than the left-most column)" do
      expect(table.transpose(column_width: 3, headers: -> (n) { n * 2 }).to_s).to eq \
        %q(+---------+-----+-----+-----+
           |         |  2  |  4  |  6  |
           +---------+-----+-----+-----+
           |       N |   1 |   2 |   3 |
           | Doubled |   2 |   4 |   6 |
           +---------+-----+-----+-----+).gsub(/^ +/, "")
    end
  end

  describe "#formatted_body_row" do
    context "when passed `header: true`" do
      it "returns a string representing a row in the body of the table, with a header" do
        expect(table.formatted_body_row(3, header: true, divider: false)).to eq \
          %q(+--------------+--------------+
             |       N      |    Doubled   |
             +--------------+--------------+
             |            3 |            6 |).gsub(/^ +/, "")
      end
    end

    context "when passed `header: false" do
      context "when passed `divider: false`" do
        it "returns a string representing a row in the body of the table, without a header" do
          expect(table.formatted_body_row(3, header: false, divider: false)).to \
            eq("|            3 |            6 |")
        end
      end

      context "when passed `divider: true`" do
        it "returns a string representing a row in the body of the table, without a header" do
          expect(table.formatted_body_row(3, header: false, divider: true)).to eq \
            %q(+--------------+--------------+
               |            3 |            6 |).gsub(/^ +/, "")
        end
      end
    end
  end
end
