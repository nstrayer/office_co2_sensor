<script lang="ts">
  function roundTo(x: number, precision: number) {
    const multiplier = Math.pow(10, precision);

    return Math.round(x * multiplier) / multiplier;
  }
  export let unit: string;
  export let values: number[];

  // const precision = 10e3;

  $: avg_val = roundTo(
    values.reduce((s, x) => s + x / values.length, 0),
    1
  );
</script>

<div class="readings">
  <slot name="name" />
  <span>{avg_val} {unit}</span>
</div>

<style>
  .readings {
    display: grid;
    grid-template-columns: 1fr 1fr;
    justify-content: center;
    gap: 1rem;
    padding: 0.5rem;
    font-size: 1.2rem;
  }
  /* :global() here means that any span not just those inside this component are
  considered. */
  .readings > :global(span):nth-child(odd) {
    justify-self: end;
  }
  .readings > *:nth-child(even) {
    justify-self: start;
    font-weight: bold;
  }
</style>
