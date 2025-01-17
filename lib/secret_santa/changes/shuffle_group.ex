defmodule SecretSanta.Changes.ShuffleGroup do
  @moduledoc """
  An `Ash.Resource.Change` module that shuffles the `SecretSanta.Groups.Group`'s
  pairings.
  """

  use Ash.Resource.Change

  require Logger

  alias SecretSanta.Groups.Pair

  @impl true
  def atomic?() do
    true
  end

  @impl true
  def atomic(changeset, [data_key: data_key], _context) do
    changeset
    |> change_p(data_key)
  end

  # ! private functions

  defp change_p(changeset, data_key) do
    changeset
    |> Ash.Changeset.get_data(data_key)
    |> Enum.map(& &1.id)
    |> shuffle()
    |> case do
      {:ok, pairs} ->
        {:ok,
         changeset
         |> Ash.Changeset.change_attribute(:pairs, pairs)}

      {:error, :empty_list} ->
        {:ok, changeset}

      {:error, :invalid_pairings} ->
        raise RuntimeError, "should never be here! Fix this bug"
    end
  end

  defp shuffle([]) do
    {:error, :empty_list}
  end

  defp shuffle([_one]) do
    {:error, :too_few_users}
  end

  defp shuffle([_one, _two]) do
    {:error, :too_few_users}
  end

  defp shuffle(user_ids = [element | _]) when is_list(user_ids) and is_binary(element) do
    shuffle_p(user_ids)
  end

  defp shuffle_p(user_ids) do
    user_ids
    |> pairing()
    |> validate_pairings()
    |> case do
      result = {:ok, _pairings} ->
        result

      {:error, :invalid_pairings} ->
        Logger.info("Reshuffling as somebody got themselves")
        shuffle_p(user_ids)

      other_error ->
        Logger.error("Unknown error occurred: #{inspect(other_error, pretty: true)}",
          crash_reason: other_error
        )

        {:error, :unknown_error}
    end
  end

  defp pairing(user_ids) do
    [first | rest] = user_ids = Enum.shuffle(user_ids)

    user_ids
    |> Enum.zip(rest ++ [first])
    |> Enum.reduce(
      [],
      fn {lhs, rhs}, acc ->
        with {:ok, pair} <- Pair.create(%{participant_id: lhs, target_id: rhs}) do
          [pair | acc]
        end
      end
    )
  end

  defp validate_pairings(pairings) do
    pairings
    |> Enum.any?(&(&1.target_id == &1.participant_id))
    |> case do
      true ->
        {:error, :invalid_pairings}

      false ->
        {:ok, pairings}
    end
  end
end
