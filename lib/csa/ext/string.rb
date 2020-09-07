#!/usr/bin/env ruby

class String
  def capitalize_first
    str = self.slice(0, 1).capitalize + self.slice(1..-1)
    str
  end
end
