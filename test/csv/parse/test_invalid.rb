# -*- coding: utf-8 -*-
# frozen_string_literal: false

require_relative "../helper"

class TestCSVParseInvalid < Test::Unit::TestCase
  def test_no_column_mixed_new_lines
    error = assert_raise(CSV::MalformedCSVError) do
      CSV.parse("\n" +
                "\r")
    end
    assert_equal("New line must be <\"\\n\"> not <\"\\r\"> in line 2.",
                 error.message)
  end
end
