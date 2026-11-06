# frozen_string_literal: true

require_relative "helper"

class TestCSVPatternMatching < Test::Unit::TestCase

  def test_hash
    case CSV::Row.new(%i{A B C}, [1, 2, 3])
    in B: b, C: c
      assert_equal([2, 3], [b, c])
    end
  end

  def test_hash_rest
    case CSV::Row.new(%i{A B C}, [1, 2, 3])
    in B: b, **rest
      assert_equal([2, { A: 1, C: 3 }], [b, rest])
    end
  end

  def test_hash_with_converted_headers
    data = CSV.parse(csv_source, headers: true, header_converters: :symbol)
    selected = data.select do |row|
      case row
      in name: /^J/
        true
      else
        false
      end
    end

    assert_equal([:name, :department, :salary], data.headers)
    assert_equal([["Jane", "Sales", "2000"], ["John", "Management", "5000"]],
                 selected.map(&:fields))
  end

  def test_patterns_with_string_headers
    data = CSV.parse(csv_source, headers: true)
    selected = data.select do |row|
      case row
      in Name: /^J/
        true
      else
        false
      end
    end
    assert_empty(selected)
    assert_equal(["Name", "Department", "Salary"], data.headers)

    selected = data.select do |row|
      case row
      in [/^J/, _, _]
        true
      else
        false
      end
    end
    assert_equal([["Jane", "Sales", "2000"], ["John", "Management", "5000"]],
                 selected.map(&:fields))
  end

  def test_array
    case CSV::Row.new(%i{A B C}, [1, 2, 3])
    in *, matched
      assert_equal(3, matched)
    end
  end

  private

  def csv_source
    <<~CSV
      Name,Department,Salary
      Bob,Engineering,1000
      Jane,Sales,2000
      John,Management,5000
    CSV
  end
end
