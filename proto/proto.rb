require 'pry'
binary = File.read('txnlog.dat')
io = File.open('txnlog.dat')
header             = io.read(9)
header_minus_magic = header.slice(4,header.length-1)
magic_string       = header.slice(0,4)
version            = header_minus_magic.slice(0).unpack('C').first
num_records        = header_minus_magic.slice(1,4).unpack('N').first

first_record           = io.read(21)
first_record_type      = first_record.slice(0,1)
first_record_timestamp = first_record.slice(1,4).unpack('N').first
first_record_user_id   = first_record.slice(5,8).unpack('Q>').first
first_record_amount    = first_record.slice(13,8).unpack('G').first

binding.pry

