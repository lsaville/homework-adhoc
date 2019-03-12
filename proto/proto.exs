require IEx

defmodule Proto do
  def main do
    { _status, binary } = File.read('txnlog.dat')

    handle_header(binary)
  end

  def handle_header(binary) do
    << magic_string :: binary-size(4), version :: integer, num_records :: big-integer-32, rest :: binary >> = binary

    handle_records(rest, %{
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

  def handle_records(<< 0, rest :: binary >>, acc) do
    handle_four_field("Debit", rest, acc)
  end
  def handle_records(<< 1, rest :: binary >>, acc) do
    handle_four_field("Credit", rest, acc)
  end
  def handle_records(<< 2, rest :: binary >>, acc) do
    handle_three_field("StartAutopay", rest, acc)
  end
  def handle_records(<< 3, rest :: binary >>, acc) do
    handle_three_field("EndAutopay", rest, acc)
  end
  def handle_records("", acc) do
    display_results(acc)
  end

  def handle_four_field(type, binary, acc) do
    << timestamp :: big-integer-32, user_id :: big-integer-64, amount :: float, rest :: binary >> = binary

    record = %{
      type: type,
      timestamp: timestamp,
      user_id: user_id,
      amount: amount
    }

    type_key = String.to_atom("#{String.downcase(type)}_total")

    acc = %{
      acc | :records => [record | acc.records],
      type_key => (acc[type_key] + amount)
    }

    handle_records(rest, acc)
  end

  def handle_three_field(type, binary, acc) do
    << timestamp :: big-integer-32, user_id :: big-integer-64, rest :: binary >> = binary

    record = %{
      type: type,
      timestamp: timestamp,
      user_id: user_id
    }

    type_key = String.to_atom("#{String.downcase(type)}_count")

    acc = %{
      acc | :records => [record | acc.records],
      type_key => (acc[type_key] + 1)
    }

    handle_records(rest, acc)
  end

  def display_results(acc) do
    special_user_record = Enum.find(acc.records, &( &1.user_id == 2456938384156277127 ))
    actual_number_records = length(acc.records)

    IO.puts("""
      Number of records:        #{acc.num_records}
      Actual number of records: #{actual_number_records}
      Magic string:             #{acc.magic_string}
      Version:                  #{acc.version}
      Debit total:              #{acc.debit_total}
      Credit total:             #{acc.credit_total}
      Autopay starts:           #{acc.startautopay_count}
      Autopay end:              #{acc.endautopay_count}
      Special user balance:     #{special_user_record.amount}
    """)
  end
end
