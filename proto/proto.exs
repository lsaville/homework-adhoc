require IEx

defmodule Proto do

  def digest do
    with {:ok, binary}         <- File.read('txnlog.dat'),
         {:ok, {acc, records}} <- handle_header(binary),
         {:ok, acc}            <- handle_records(records, acc) do
         display_results(acc)
    else
      {:error, file_read_error} ->
        IO.puts("File read error: #{file_read_error}")
      {:error, header_error} ->
        IO.puts("Header error: #{header_error}")
      {:error, record_error} ->
        IO.puts("Record error: #{record_error}")
    end
  end

  def handle_header(binary) do
    << magic_string :: binary-size(4), version :: integer, num_records :: big-integer-32, rest :: binary >> = binary

    {
      :ok,
      {
        %{
          credit_total: 0,
          debit_total: 0,
          endautopay_count: 0,
          magic_string: magic_string,
          num_records: num_records,
          records: [],
          startautopay_count: 0,
          version: version,
        },
        rest
      }
    }
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
    {:ok, acc}
    #display_results(acc)
  end

  def handle_records(records, acc) do
    << type :: binary-size(1), rest :: binary >> = records

    case type do
      0 ->
        handle_four_field("Debit", rest, acc)
      1 ->
        handle_four_field("Credit", rest, acc)
      2 ->
        handle_three_field("StartAutopay", rest, acc)
      3 ->
        handle_three_field("EndAutopay", rest, acc)
      "" ->
        display_results(acc)
    end
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
