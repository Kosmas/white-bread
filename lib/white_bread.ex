defmodule WhiteBread do
  def run(context, path, options \\ []) do
    tags = options |> Keyword.get(:tags)

    output = WhiteBread.Outputers.Console.start

    features = path
      |> WhiteBread.Feature.Finder.find_in_path
      |> read_in_feature_files
      |> parse_features
      |> filter_features(tags)

    results = features
      |> run_all_features(context, output)
      |> results_as_map
      |> output_result(output)

    output |> WhiteBread.Outputers.Console.stop

    results
  end

  defp results_as_map(results) do
    %{
      successes: results |> Enum.filter(&feature_success?/1),
      failures:  results |> Enum.filter(&feature_failure?/1)
    }
  end

  defp output_result(result_map, output_pid) when is_pid(output_pid)  do
     send(output_pid, {:final_results, result_map})
     result_map
  end

  defp read_in_feature_files(file_paths) do
    file_paths |> Stream.map(&File.read!/1)
  end

  defp parse_features(feature_texts) do
    feature_texts
    |> Enum.map(&parse_task/1)
    |> Enum.map(&Task.await/1)
  end

  defp parse_task(feature_text) do
    Task.async(fn -> WhiteBread.Gherkin.Parser.parse_feature(feature_text) end)
  end

  defp filter_features(features, _tags = nil) do
    features
  end
  defp filter_features(features, tags) do
    features |> WhiteBread.Tags.FeatureFilterer.get_for_tags(tags)
  end

  defp run_all_features(features, context, output) do
    features |> Enum.map(get_feature_runner(context, output))
  end

  defp get_feature_runner(context, output) do
    fn(feature) ->
      {feature, WhiteBread.Runners.FeatureRunner.run(feature, context, output)}
    end
  end

  defp feature_success?({_feature, %{failures: failures}}) do
    failures == []
  end

  defp feature_failure?({_feature, %{failures: failures}}) do
    failures != []
  end
end
