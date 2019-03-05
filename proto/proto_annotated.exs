require IEx

defmodule Proto do
  def main do
    { _status, binary } = File.read('txnlog.dat')

    handleHeader(binary)
  end

  def handleHeader(binary) do
    << magic_string :: binary-size(4), version :: integer, num_records :: big-integer-32, rest :: binary >> = binary

    handleRecords(rest, %{
      magic_string: magic_string,
      version: version,
      num_records: num_records,
      records: [],
      debit_total: 0,
      credit_total: 0,
      startautopay_count: 0,
      endautopay_count: 0,
    })
  end

  def handleRecords(<< 0, rest :: binary >>, acc) do
    handleFourField("Debit", rest, acc)
  end
  def handleRecords(<< 1, rest :: binary >>, acc) do
    handleFourField("Credit", rest, acc)
  end
  def handleRecords(<< 2, rest :: binary >>, acc) do
    handleThreeField("StartAutopay", rest, acc)
  end
  def handleRecords(<< 3, rest :: binary >>, acc) do
    handleThreeField("EndAutopay", rest, acc)
  end
  def handleRecords("", acc) do
    displayResults(acc)
  end

  def handleFourField(type, binary, acc) do
    << timestamp :: big-integer-32, user_id :: big-integer-64, amount :: float, rest :: binary >> = binary

    record = %{
      type: type,
      timestamp: timestamp,
      user_id: user_id,
      amount: amount
    }

    type_key = String.to_atom("#{String.downcase(type)}_total")

    acc = acc 
          |> Map.update(:records, [], &[ record | &1 ])
          |> Map.update(type_key, 0, &( &1 + amount ))

    handleRecords(rest, acc)
  end

  def handleThreeField(type, binary, acc) do
    << timestamp :: big-integer-32, user_id :: big-integer-64, rest :: binary >> = binary

    record = %{
      type: type,
      timestamp: timestamp,
      user_id: user_id
    }

    type_key = String.to_atom("#{String.downcase(type)}_count")

    acc = acc 
          |> Map.update(:records, [], &[ record | &1 ])
          |> Map.update(type_key, 0, &( &1 + 1 ))

    handleRecords(rest, acc)
  end

  def displayResults(acc) do
    special_user_record = Enum.find(acc.records, &( &1.user_id == 2456938384156277127 ))
    actual_number_records = length(acc.records)

    IO.puts "============ Results ============="
    IO.puts "Number of records:        #{acc.num_records}"
    IO.puts "Actual number of records: #{actual_number_records}"
    IO.puts "Magic string:             #{acc.magic_string}"
    IO.puts "Version:                  #{acc.version}"
    IO.puts "Debit total:              #{acc.debit_total}"
    IO.puts "Credit total:             #{acc.credit_total}"
    IO.puts "Autopay starts:           #{acc.startautopay_count}"
    IO.puts "Autopay end:              #{acc.endautopay_count}"
    IO.puts "Special user balance:     #{special_user_record.amount}"
  end
end
