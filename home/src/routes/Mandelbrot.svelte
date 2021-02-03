<script>
  import { mandelbrot } from "./mandelbrot.js";

  let mandelbrotCanvas;
  $: mandelbrotCanvas && mandelbrot(mandelbrotCanvas);
</script>

<canvas width="480" height="320" bind:this={mandelbrotCanvas} />
