set tool_name "Vivado"
set clock_period 10.0

puts "Tool: $tool_name, Clock Period: $clock_period ns"
set freq_mhz [expr {1000.0/$clock_period}]
puts "Target Frequency: $freq_mhz MHz"