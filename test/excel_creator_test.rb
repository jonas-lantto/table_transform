require_relative 'test_helper'
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
    t = TableTransform::Table.create_empty(%w(Name Income Tax))
    t << {'Name' => 'Joe',  'Income' => 500000,  'Tax' => 0.15}

    assert_equal([7,9,6], TableTransform::ExcelCreator::column_width(t, true), 'Auto filter correction')
    assert_equal([4,6,4], TableTransform::ExcelCreator::column_width(t, false))

    #maximum header width per column
    assert_equal([4,5,4], TableTransform::ExcelCreator::column_width(t, false, 5))

    #nil value
    t << {'Name' => nil,  'Income' => nil,  'Tax' => nil}
    assert_equal([4,6,4], TableTransform::ExcelCreator::column_width(t, false))

    #format, simple
    t.column_properties['Tax'].update({format: '???.???'})
    assert_equal([4,6,7], TableTransform::ExcelCreator::column_width(t, false))

    #format, advanced
    t.column_properties['Tax'].update({format: '[>100][GREEN]#,##0;[<=-100][YELLOW]##,##0;[CYAN]#,##0'})
    assert_equal([4,6,6], TableTransform::ExcelCreator::column_width(t, false))
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
    excel.create!
    
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

  def test_format
    t = TableTransform::Table.create_empty(%w(Name Income Dept Tax))
    t << {'Name' => 'Joe',  'Income' => 500_000,   'Dept' => 43_000,  'Tax' => 0.15}
    t << {'Name' => 'Jane', 'Income' => 1_300_000, 'Dept' => 180_000, 'Tax' => 0.5672}

    %w(Income Tax Dept).each{|k| t.column_properties[k].update({format: '#,##0'})}
    t.column_properties['Tax'].update({format: '0.00%'})

    excel = TableTransform::ExcelCreator.new(@tmp_filename)
    excel.add_tab('format_tab', t)
    assert_equal(2, excel.instance_eval{@formats.size})

    excel.add_tab('format_tab_select', t.extract(%w(Income)))
    assert_equal(2, excel.instance_eval{@formats.size})

    excel.create!

    xlsx = Roo::Excelx.new(@tmp_filename)
    assert_equal(%w(format_tab format_tab_select), xlsx.sheets)

    # note
    # Roo supports only a subset of all formats Excel covers.
    # This test adapted to the Roo subset to verify formats are set at expected - not the format itself
    sheet = xlsx.sheet('format_tab')
    assert_equal('500,000', sheet.formatted_value(2, 'B'))
    assert_equal('1,300,000', sheet.formatted_value(3, 'B'))

    assert_equal('43,000', sheet.formatted_value(2, 'C'))
    assert_equal('180,000', sheet.formatted_value(3, 'C'))

    assert_equal('15.00%', sheet.formatted_value(2, 'D'))
    assert_equal('56.72%', sheet.formatted_value(3, 'D'))

    sheet = xlsx.sheet('format_tab_select')
    assert_equal('500,000', sheet.formatted_value(2, 'A'))
    assert_equal('1,300,000', sheet.formatted_value(3, 'A'))
  end

  def test_formulas
    t = TableTransform::Table.create_empty(%w(Name Income))
    t << {'Name' => 'Joe',  'Income' => 500_000}
    t << {'Name' => 'Jane', 'Income' => 1_300_000}

    t.add_column_formula('OnePlusOne', '1+1')
    t.add_column_formula('One1000One', '1+1000', {format: '#,##0'})

    # Create Excel
    excel = TableTransform::ExcelCreator.new(@tmp_filename)
    excel.add_tab('formula_tab', t)
    excel.create!

    xlsx = Roo::Excelx.new(@tmp_filename)
    assert_equal(%w(formula_tab), xlsx.sheets)
    sheet = xlsx.sheet('formula_tab')
    assert_equal('1+1', sheet.formula(2, 'C'))
    assert_equal('1+1', sheet.formula(3, 'C'))
    assert_equal(nil, sheet.formula(4, 'C'))

    assert_equal('1+1000', sheet.formula(2, 'D'))
    assert_equal('1+1000', sheet.formula(3, 'D'))
  end
end