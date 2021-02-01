<script>
  import { onMount } from "svelte";
  import { stores } from "@sapper/app";
  import Soundfont from "soundfont-player";
  import Table from "../../components/Table.svelte";
  import { takeWhile } from "lodash";

  // destroy the audio if we navigate away from the page
  const { page } = stores();

  export let track;
  let ac;
  let instrument;
  let notes;

  let playing = false;
  let timer;
  let noteOffset = 0;
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

  function tickToSeconds(tick, bpm, ppq = 192) {
    return (60 / (bpm * ppq)) * tick;
  }

  onMount(async () => {
    ac = new window.AudioContext();

    instrument = await Soundfont.instrument(ac, "acoustic_grand_piano");
    notes = track
      .filter(e => e.name == "Note on")
      .map(e => ({ time: tickToSeconds(e.tick, 140), note: e.noteNumber }));
    duration = notes[notes.length - 1].time;
  });

  function play() {
    // every 16th of a second, schedule more notes
    // not sure if this is going to sound funny...
    let interval = 1 / 16;
    if (!instrument) {
      return;
    }
    timer = setInterval(() => {
      let notesToPlay = takeWhile(notes.slice(noteOffset), o => {
        return currentTime <= o.time && o.time < currentTime + interval;
      });
      if (notesToPlay.length < 0) {
        stop();
        return;
      }
      instrument.schedule(ac.currentTime, notesToPlay);
      noteOffset += notesToPlay.length;
      currentTime += interval;
    }, interval * 1000);
    playing = true;
  }

  function stop() {
    clearInterval(timer);
    instrument.stop();
    playing = false;
  }
</script>

<div>
  {#if playing}
    <button on:click={stop}>Stop</button>
  {:else}
    <button on:click={play}>Play</button>
  {/if}
  <span>{currentTime.toFixed(1)} / {duration.toFixed(1)}</span>
</div>

<Table data={track} options={{ pagination: 'local', paginationSize: 10 }} />
