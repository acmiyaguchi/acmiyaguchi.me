<script>
  import { mandelbrot } from "./mandelbrot.js";

  let mandelbrotCanvas;
  $: mandelbrotCanvas && mandelbrot(mandelbrotCanvas);
</script>

<canvas id="mandelbrot" width="480" height="320" bind:this={mandelbrotCanvas} />
