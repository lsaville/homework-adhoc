require IEx;

defmodule Proto do
  def main do
    { status, binary } = File.read('../txnlog.dat')
    << magic_string :: binary-size(4), version :: integer, num_records :: big-integer-32, rest :: binary >> = binary
    IEx.pry
  end

  def handle_rest(<< record_type :: integer, rest :: binary >>) when record_type in [0,1] do
    parse_n_print_long(record_type, << timestamp :: big-integer-32, user_id :: big-integer-64, IM BROKEN LOOK HERE  >>)
  end
  def handle_rest(<< record_type :: integer, rest :: binary >>) when record_type in [2,3] do
  end
end
