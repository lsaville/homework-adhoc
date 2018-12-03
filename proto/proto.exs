module Proto
  def main
    { status, binary } = File.read('txnlog.dat')
    << magic_string :: binary-size(4), version :: integer, num_records :: big-integer-32, rest :: binary >> = binary
    IEx.pry
  end
end
