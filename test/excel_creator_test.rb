require 'minitest/autorun'
require 'benchmark'
require 'pathname'
require 'table_transform'
require 'roo'
require 'securerandom'


class ExcelCreatorTest < Minitest::Test

  def setup
    @tmp_filename = Pathname(Dir.tmpdir) + ('TableTransform' + SecureRandom.uuid + '.xlsx')
  end
  def teardown
    File.delete(@tmp_filename) if File.exist?(@tmp_filename)
  end

  def test_column_width
    # empty
    assert_equal([], TableTransform::ExcelCreator::column_width([], true))

    #header and row
    data = [['AAA', 23],
            ['BBBB', 4]]
    assert_equal([6,5], TableTransform::ExcelCreator::column_width(data, true), 'Auto filter correction')
    assert_equal([4,2], TableTransform::ExcelCreator::column_width(data, false))

    #maximum header width per column
    data = [['333', '4444', 55555]]
    assert_equal([3,4,4], TableTransform::ExcelCreator::column_width(data, false, 4))

    #different types
    data = [[12.0, 33.33, nil]]
    assert_equal([4,5,0], TableTransform::ExcelCreator::column_width(data, false))
  end

  def test_excel_create
    data1 = [%w(Col1 Col2),
            ['StR', 32],
            [nil, 65.23]]

    excel = TableTransform::ExcelCreator.new(@tmp_filename)
    excel.add_tab('data1', TableTransform::Table.new(data1))
    excel.add_tab('Data Header only', TableTransform::Table.new([%w(Col1 Col2)]))
    excel.add_tab('Data Nil', nil)
    excel.add_tab('Data Empty', [])
    excel.close                                                              
    
    xlsx = Roo::Excelx.new(@tmp_filename)
    assert_equal(['data1', 'Data Header only','Data Nil', 'Data Empty'], xlsx.sheets)

    sheet = xlsx.sheet('data1')
      assert_equal('Col1', sheet.cell(1, 'A'))
      assert_equal('Col2', sheet.cell(1, 'B'))
      assert_equal(nil,    sheet.cell(1, 'C'))

      assert_equal('StR', sheet.cell(2, 'A'))
      assert_equal(32,    sheet.cell(2, 'B'))
      assert_equal(nil,   sheet.cell(2, 'C'))

      assert_equal(nil,   sheet.cell(3, 'A'))
      assert_equal(65.23, sheet.cell(3, 'B'))
      assert_equal(nil,   sheet.cell(3, 'C'))

      assert_equal(nil,   sheet.cell(4, 'A'))
      assert_equal(nil,   sheet.cell(4, 'B'))
      assert_equal(nil,   sheet.cell(4, 'C'))

    sheet = xlsx.sheet('Data Header only')
      assert_equal('Col1', sheet.cell(1, 'A'))
      assert_equal('Col2', sheet.cell(1, 'B'))
      assert_equal(nil,    sheet.cell(1, 'C'))

      assert_equal(nil,     sheet.cell(2, 'A'))
      assert_equal(nil,     sheet.cell(2, 'B'))
      assert_equal(nil,     sheet.cell(2, 'C'))

    sheet = xlsx.sheet('Data Nil')
      assert_equal(nil,     sheet.cell(1, 'A'))

    sheet = xlsx.sheet('Data Empty')
      assert_equal(nil,     sheet.cell(1, 'A'))

  end
end