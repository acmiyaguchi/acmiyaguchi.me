<script context="module">
  export async function preload({ params }) {
    // the `slug` parameter is available because
    // this file is called [slug].html
    const res = await this.fetch(`piano/${params.slug}.json`);
    const data = await res.json();
    if (res.status === 200) {
      return { midi: data };
    } else {
      this.error(res.status, data.message);
    }
  }
</script>

<script>
  import Soundfont from "soundfont-player";
  import { onMount } from "svelte";

  export let midi;
  let ac;
  let instrument;
  let notes;

  function getLongestTrack(midi) {
    // https://stackoverflow.com/a/33579314
    let idx = midi.reduce(
      (pending, cur, idx, arr) =>
        arr[pending].length > cur.length ? pending : idx,
      0
    );
    return midi[idx];
  }

  onMount(async () => {
    ac = new window.AudioContext();

    instrument = await Soundfont.instrument(ac, "acoustic_grand_piano");
    let track = getLongestTrack(midi);
    // TODO: only schedule a few in advance, otherwise the audio starts to heavily crack.
    notes = track
      .filter(e => e.name == "Note on")
      .map(e => ({ time: e.tick / (140 * 4), note: e.noteNumber }));
    instrument.schedule(ac.currentTime, notes);
  });
</script>

<pre>{JSON.stringify(notes, '', 2)}</pre>
