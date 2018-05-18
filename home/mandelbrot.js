window.onload = mandelbrot;

function mandelbrot() {
  var canvas = document.getElementById('mandelbrot');
  var ctx = canvas.getContext('2d');

  var width = canvas.width;
  var height = canvas.height;

  var imageData = ctx.createImageData(width, height);

  // Wikipedia Mandelbrot set article
  for (i=0; i < width; i++) {
    var x0 = (i / width) * 3.5 - 2.5;
    for(j=0; j < height; j++) {
      var y0 = (j / height) * 2 - 1;
      var x = 0;
      var y = 0;
      var iteration = 0;
      max_iteration = 1000;
      // Choose N = 2^8
      while (x*x + y*y < (1 << 16) && iteration < max_iteration) {
        var xtemp = x*x - y*y + x0;
        y = 2*x*y + y0;
        x = xtemp;
        iteration += 1;
      }
      // avoid floating point issues
      if (iteration < max_iteration) {
        log_zn = Math.log(x*x + y*y) / 2;
        nu = Math.log(log_zn/Math.log(2))/Math.log(2);
        iteration = iteration+1-nu;
      }

			interval = iteration / max_iteration;
			// hue-saturation-value is much easier to do smooth coloring

			rgb = HSVtoRGB(0.65+10*interval, 0.6, 1.0);
      setPixel(imageData, i, j, rgb.r, rgb.g, rgb.b, 255);
    }
  }

  ctx.putImageData(imageData, 0, 0);
};

function setPixel(imageData, x, y, r, g, b, a) {
  index = (x + y * imageData.width) * 4;
  imageData.data[index+0] = r;
  imageData.data[index+1] = g;
  imageData.data[index+2] = b;
  imageData.data[index+3] = a;
}

// Source: http://stackoverflow.com/questions/17242144/javascript-convert-hsb-hsv-color-to-rgb-accurately#comment24984878_17242144
function HSVtoRGB(h, s, v) {
    var r, g, b, i, f, p, q, t;
    if (arguments.length === 1) {
        s = h.s, v = h.v, h = h.h;
    }
    i = Math.floor(h * 6);
    f = h * 6 - i;
    p = v * (1 - s);
    q = v * (1 - f * s);
    t = v * (1 - (1 - f) * s);
    switch (i % 6) {
        case 0: r = v, g = t, b = p; break;
        case 1: r = q, g = v, b = p; break;
        case 2: r = p, g = v, b = t; break;
        case 3: r = p, g = q, b = v; break;
        case 4: r = t, g = p, b = v; break;
        case 5: r = v, g = p, b = q; break;
    }
    return {
        r: Math.round(r * 255),
        g: Math.round(g * 255),
        b: Math.round(b * 255)
    };
}
