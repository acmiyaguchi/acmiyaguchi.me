import MidiPlayer from "midi-player-js";
import fetch from "node-fetch";

function getLongestTrack(midi) {
  // https://stackoverflow.com/a/33579314
  let idx = midi.reduce(
    (pending, cur, idx, arr) =>
      arr[pending].length > cur.length ? pending : idx,
    0
  );
  return midi[idx];
}

export async function get(req, res, next) {
  const { slug } = req.params;
  let url = `https://storage.googleapis.com/acmiyaguchi/midi/${slug}.mid`;
  let resp = await fetch(url);
  let data = await resp.arrayBuffer();
  let Player = new MidiPlayer.Player();
  Player.loadArrayBuffer(data);
  Player.dryRun();
  // Only keep the longest track, since I'm only playing a single instrument. One
  // day, I suppose I could write something that takes advantage of multiple
  // tracks.
  res.end(JSON.stringify(getLongestTrack(Player.events)));
}
