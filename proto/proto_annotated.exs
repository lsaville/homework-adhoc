require IEx

# I've got the thing organized as a flow from the file to the result. I pulled
# this example from the job process at Ad-Hoc, my friend was going through the
# process and actually just got a job there. Anyway I saw this and played with
# it a little in Ruby just as a wow-look-at-the-funny-strings/characters kind
# of thing and realized that Elixir's binary pattern matching is made from
# problems just like this!
#
# I could see an extension to this version being one where Streams were
# utilized. The prompt specifically says the file is relatively short, but
# a relatively small change in requirements could cause the memory space of
# this implementation to choke under a larger burden.
#
# Oh also, I neglected error handling... wah wah

defmodule Proto do
  def main do
    { _status, binary } = File.read('txnlog.dat')

    handleHeader(binary)
  end

  def handleHeader(binary) do
    # Maybe there's a special formatting that I'm not aware of for a big match?
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

  # I feel like maybe this portion would be better as a case?
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

    # This felt dirty, I suppose it depends on the audience. As an alternative
    # I could see matching on the "Debit" or "Credit" and passing an extra arg
    # as the key...
    #
    # Another thing that kinda put me on edge when I was figuring out how to
    # update a Map, what if I didn't want a default in case the lookup failed?
    # I suppose you provide the least harmful default. There is also the
    # possibility that my problem is one of mindset, that I'm too used to the
    # wild-west and the restraints on this v-small system would be such that
    # I'd never be making new entries just for the lolz on accident.
    type_key = String.to_atom("#{String.downcase(type)}_total")

    # Is there a more elegant way to alter acc? Maybe do the pipelines in the
    # param list of handleRecords?
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
