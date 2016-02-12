require 'minitest/autorun'
require 'benchmark'
require 'table_transform/excel_creator'


class ExcelCreatorTest < Minitest::Test

  def test_column_width
    # empty
    assert_equal([], TableTransform::ExcelCreator::Util.column_width([], true))

    #header and row
    data = [['AAA', 23],
            ['BBBB', 4]]
    assert_equal([6,5], TableTransform::ExcelCreator::Util.column_width(data, true), "Auto filter correction")
    assert_equal([4,2], TableTransform::ExcelCreator::Util.column_width(data, false))

    #maximum header width per column
    data = [['333', '4444', 55555]]
    assert_equal([3,4,4], TableTransform::ExcelCreator::Util.column_width(data, false, 4))

    #different types
    data = [[12.0, 33.33, nil]]
    assert_equal([4,5,0], TableTransform::ExcelCreator::Util.column_width(data, false))
  end

end