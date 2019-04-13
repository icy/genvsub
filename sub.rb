#!/usr/bin/env ruby

# Author  : Ky-Anh Huynh
# Purpose : Alternative of system envsubst

$exit_on_nil = ARGV.include?("-set-u")

STDIN.each_line do |line|
  line.gsub!(%r{\$\{([^\}]+)\}}) do |m|
    case ENV[$1]
    when nil
      if $exit_on_nil
        raise RuntimeError, ":: Environment variable '#{$1}' is not set."
      else
        STDERR.puts ":: Environment variable '#{$1}' is not set."
      end
    else
      ENV[$1]
    end
  end

  puts line
end
