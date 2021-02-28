import App from "./App.svelte";
import wasm from "../chip8-core/Cargo.toml";

async function init() {
  new App({
    target: document.body,
    props: { lib: await wasm() },
  });
}

init();
