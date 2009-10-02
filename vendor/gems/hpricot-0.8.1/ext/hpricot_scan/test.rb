require './hpricot_scan.so'

doc = "<doc><person><test>YESSS</test></person><train>SET</train></doc>"
p Hpricot.scan(doc)
