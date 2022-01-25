<script lang="ts">
  import SummaryLine from "./SummaryLine.svelte";

  type Reading = { time: string; co2: number; temp: number; humidity: number };
  let air_readings: Reading[] = [];

  // Make sure that the vectors of data all keep updated witih the data
  $: co2 = air_readings.map((r) => r.co2);
  $: temp = air_readings.map((r) => r.temp * (9 / 5) + 32);
  $: humidity = air_readings.map((r) => r.humidity);

  // Pull data from Pie server and update the air_readings variable
  fetch("http://10.0.0.30:8888/data?nlines=50")
    .then((response) => response.json())
    .then((data) => {
      air_readings = data.readings as Reading[];
    });
</script>

<h2>Summary of recent office air readings</h2>
<SummaryLine unit="degrees" values={temp}>
  <span slot="name">Temperature:</span>
</SummaryLine>
<SummaryLine unit="%" values={humidity}>
  <span slot="name">Humidity:</span>
</SummaryLine>
<SummaryLine unit="ppm" values={co2}>
  <span slot="name">CO<sub>2</sub></span>
</SummaryLine>
