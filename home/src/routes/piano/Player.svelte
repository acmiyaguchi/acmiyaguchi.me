<script>
  import Soundfont from "soundfont-player";
  import { onMount } from "svelte";
  import { stores } from "@sapper/app";
  import Table from "../../components/Table.svelte";

  // destroy the audio if we navigate away from the page
  const { page } = stores();

  export let track;
  let ac;
  let instrument;
  let notes;

  // https://github.com/sveltejs/sapper/issues/633
  // I'm not sure why I can't use the page directly -- it doesn't seem to
  // capture the page events properly.
  let path = $page.path;
  page.subscribe(p => {
    if (!instrument) {
      return;
    }

    if (p.path != path) {
      instrument.stop();
    }
  });

  onMount(async () => {
    ac = new window.AudioContext();

    instrument = await Soundfont.instrument(ac, "acoustic_grand_piano");
    // TODO: only schedule a few in advance, otherwise the audio starts to heavily crack.
    notes = track
      .filter(e => e.name == "Note on")
      .map(e => ({ time: e.tick / (140 * 4), note: e.noteNumber }));
    instrument.schedule(ac.currentTime, notes);
  });
</script>

<Table
  data={track}
  options={{ pagination: 'local', paginationSize: 10 }}
  deleteColumns={['track', 'string']} />
