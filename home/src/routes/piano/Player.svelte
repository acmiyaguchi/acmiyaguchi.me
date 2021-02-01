<script>
  import { onMount } from "svelte";
  import { stores } from "@sapper/app";
  import MidiPlayer from "midi-player-js";
  import Soundfont from "soundfont-player";
  import Table from "../../components/Table.svelte";

  // destroy the audio if we navigate away from the page
  const { page } = stores();

  export let src;
  let Player;
  let instrument;
  let track;
  let notes;

  let playing = false;
  let duration = 0;
  let currentTime = 0;

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
    const resp = await fetch(src);
    const data = await resp.arrayBuffer();

    Player = new MidiPlayer.Player();
    Player.loadArrayBuffer(data);
    Player.dryRun();
    track = getLongestTrack(Player.events);
    duration = Player.getSongTime();

    let ac = new window.AudioContext();
    instrument = await Soundfont.instrument(ac, "acoustic_grand_piano");

    Player.on("playing", currentTick => {
      currentTime = duration - Player.getSongTimeRemaining();
    });
    Player.on("midiEvent", event => {
      if (event.name == "Note on") {
        instrument.play(event.noteNumber);
      }
    });
  });
</script>

<div>
  {#if playing}
    <button
      on:click={() => {
        playing = false;
        Player.stop();
      }}>
      Stop
    </button>
  {:else}
    <button
      on:click={() => {
        playing = true;
        Player.play();
      }}>
      Play
    </button>
  {/if}
  <span>{currentTime.toFixed(0)} / {duration.toFixed(0)} seconds</span>
</div>

{#if track}
  <Table data={track} options={{ pagination: 'local', paginationSize: 10 }} />
{/if}
