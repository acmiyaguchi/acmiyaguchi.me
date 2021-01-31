import MidiPlayer from "midi-player-js";
import fetch from "node-fetch";

export async function get(req, res, next) {
  const { slug } = req.params;
  let url = `https://storage.googleapis.com/acmiyaguchi/midi/${slug}.mid`;
  let resp = await fetch(url);
  let data = await resp.arrayBuffer();
  let Player = new MidiPlayer.Player();
  Player.loadArrayBuffer(data);
  Player.dryRun();
  res.end(JSON.stringify(Player.events));
}
