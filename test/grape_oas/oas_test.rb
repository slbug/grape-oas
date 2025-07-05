# frozen_string_literal: true

require "test_helper"

class GrapeOASTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::GrapeOAS::VERSION
  end

  def test_module_defined
    assert defined?(GrapeOAS)
  end
end
