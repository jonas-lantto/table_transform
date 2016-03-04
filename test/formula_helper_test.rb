require_relative 'test_helper'
require 'table_transform/formula_helper'


class FormulaHelperTest < Minitest::Test

  def test_create
      f = TableTransform::FormulaHelper
      assert_equal('"no"', f::text('no'))
      assert_equal('[C1]', f::column('C1'))
      assert_equal('T1[]', f::table('T1'))

      # VLOOKUP
      assert_equal('VLOOKUP(C1,T1[],COLUMN(T1[[#Headers],[R1]]),FALSE)',
                   f::vlookup('C1', 'T1', 'R1'))
      assert_equal('VLOOKUP([C1],T1[],COLUMN(T1[[#Headers],[R1]]),FALSE)',
                   f::vlookup(f::column('C1'), 'T1', 'R1'))
      assert_equal('IFNA(VLOOKUP([C1],T1[],COLUMN(T1[[#Headers],[R1]]),FALSE),"None")',
                   f::vlookup(f::column('C1'), 'T1', 'R1', f::text('None')))
  end
end
