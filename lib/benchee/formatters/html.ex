defmodule Benchee.Formatters.HTML do
  require EEx

  EEx.function_from_file :def, :report,
                         "priv/templates/report.html.eex",
                         [:suite, :suite_json]

  @moduledoc """
  Functionality for converting Benchee benchmarking results to an HTML page
  with plotly.js generated graphs and friends.
  """

  @doc """
  Uses `Benchee.Formatters.HTML.format/1` to transform the statistics output to
  HTML with JS, but also already writes it to a file defined in the initial
  configuration under `html: [file: "my.html"]`
  """
  def output(map)
  def output(suite = %{config: %{html: %{file: filename}}}) do
    base_directory = create_base_directory(filename)
    copy_asset_files(base_directory)

    suite
    |> format
    |> Benchee.Utility.FileCreation.each(filename)

    suite
  end
  def output(_suite) do
    raise "You need to specify a file to write the HTML to in the configuration as html: [file: \"my.html\"]"
  end

  defp create_base_directory(filename) do
    base_directory = Path.dirname filename
    File.mkdir_p! base_directory
    base_directory
  end

  @asset_directory "assets"
  defp copy_asset_files(base_directory) do
    asset_target_directory = Path.join(base_directory, @asset_directory)
    asset_source_directory = Application.app_dir(:benchee_html,
                                                 "priv/assets/")
    File.cp_r! asset_source_directory, asset_target_directory
  end

  @doc """
  Transforms the statistical results from benchmarking to html to be written
  somewhere, such as a file through `IO.write/2`.

  """
  def format(%{statistics: statistics, run_times: run_times, system: system}) do
    statistics
    |> Enum.map(fn({input, input_stats}) ->
         sorted_stats = Benchee.Statistics.sort input_stats
         input_run_times = run_times[input]
         input_json = Benchee.Formatters.JSON.format_measurements(input_stats, input_run_times)
         input_suite = %{
           statistics: sorted_stats,
           run_times:  input_run_times,
           system:     system
         }
         {input, report(input_suite, input_json)}
       end)
    |> Map.new
  end

  defp format_duration(duration) do
    Benchee.Conversion.Format.format(duration, "", "")
  end

  defp format_count(count) do
    Benchee.Conversion.Format.format({count, :one}, Benchee.Conversion.Count)
  end

  defp format_percent(deviation_percent) do
    deviation_percent
    |> Benchee.Conversion.DeviationPercent.format
    |> String.replace("±", "&plusmn;")
  end
end
