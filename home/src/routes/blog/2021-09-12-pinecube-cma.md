---
layout: post
title: CMA fragmentation with 5MP PineCube captures
date: 2021-09-12T22:40:00-08:00
category: Personal
tags:
  - pinecube
---

I've recently played with [the PineCube as a way to take plant
photos](blog/2021-09-05-pinecube-sundews) over time. In my previous post, I
figured out how to take 720p images (i.e., 1280x720). However, I found it
possible to take 5-megapixel images with a resolution of 2592x1944 as per the
product specs (note the total number of pixels is slightly larger than 5
million). While the 720p image would have been sufficient for a time-lapse, I
wanted to take advantage of the camera's full power.

<div style="max-width: 400px">
<img src="assets/2021-09-12/01-cropped-plant.png" alt="plant in 720p">
</div>
<i><b>Figured:</b> A cropped 720p photo of the sundew.</i>

I went ahead and changed some
parameters in `media-ctl` to change the resolution:

```bash
$ media-ctl --set-v4l2 "5:0[fmt:JPEG_1X8/2594x1944]"
Unable to setup formats: Invalid argument (22)
```

For some strange reason, I can't change the resolution to 5 megapixels despite
hardware support. I stumbled around for a bit and found out that I could get
higher resolution images if I changed the format to `UVYV8_2X8`, back to
`JPEG_1X8`, and then increased the resolution to 2594x1944.

```bash
resolution=2594x1944
# switch to yuv and back to jpeg to get the higher resolution to work
media-ctl --set-v4l2 "5:0[fmt:UYVY8_2X8/1280x720@1/15]"
media-ctl --set-v4l2 "5:0[fmt:JPEG_1X8/1280x720@1/15]"
media-ctl --set-v4l2 "5:0[fmt:JPEG_1X8/$resolution]"
```

After this, I could use fswebcam to take full-resolution images using ~6 frames.
If I took any more than that, the whole device would freeze up, and I would have
to restart the device physically. Why was this? I had get serial output from the
PineCube to find out that a lack of memory was causing the device to freeze.

My investigation points to the [contigous memory
allocator](https://lwn.net/Articles/486301/), an allocator with a reserved
memory section used for direct memory access. This type of memory access pattern
is expected with cameras it requires a wide bus to transfer pixels over to
memory. By default, armbian only allocates 32MB for the CMA. Trying to allocate
memory outside causes the following errors to show in system logs:

```bash
$ dmesg | tail -n5
[ 1634.394986] alloc_contig_range: [45900, 45dcf) PFNs busy
[ 1634.405538] alloc_contig_range: [45a00, 45ecf) PFNs busy
[ 1634.411952] alloc_contig_range: [45a00, 45fcf) PFNs busy
[ 1634.558555] cma: cma_alloc: alloc failed, req-size: 1231 pages, ret: -16
[ 1634.565427] sun6i-csi 1cb4000.camera: dma_alloc_coherent of size 5042176 failed
```

In particular, the camera was unable to allocate a contiguous section of 5042176
bytes (i.e. 2594x1944 bytes). Each frame takes up ~5MB, which leads to a max of
6 frames when using the highest resolution on the camera. The problem is that
the image is too dark to analyze when there are only six frames captured. I
followed the instructions from this [armbian
issue](https://github.com/armbian/build/issues/744) to increase this value to
take more photos. In the `/boot/armbianEnv.txt` file, I set the following line:

```bash
extraargs=cma=64M
```

I rebooted and found myself in kernel panic. The CMA got 64M reserved, and the
other 64M was not enough for the rest of the operating system. I had to edit the
`/boot/armbianEnv.txt` file from my desktop to fix the booting issues. I went
with 48M instead, which seemed to be a good tradeoff. I could verify that the
settings took effect by looking at `meminfo` and `dmesg` logs.

```
$ cat /proc/meminfo | grep -i cma
CmaTotal:          49152 kB
CmaFree:           19604 kB
```

```bash
$ dmesg | grep cma
[    0.000000] cma: Reserved 48 MiB at 0x44c00000
[    0.000000] Kernel command line: root=UUID=8b345056-07b6-4527-bc3a-cd63fa8abe92 rootwait rootfstype=ext4 console=ttyS0,115200 console=tty1 hdmi.audio=EDID:0 disp.screen0_output_mode=1920x1080p60 consoleblank=0 loglevel=1 ubootpart=402c6996-01 ubootsource=mmc usb-storage.quirks=0x2537:0x1066:u,0x2537:0x1068:u cma=48M  sunxi_ve_mem_reserve=0 sunxi_g2d_mem_reserve=0 sunxi_fb_mem_reserve=16 cgroup_enable=memory swapaccount=1
[    0.000000] Memory: 5390
```

And everything worked smoothly... not. I put my script in a loop using the
new resolution and a fixed number of frames to determine if I would run into
issues. It turns out that after only a single loop, the CMA would be unable to
allocate the memory necessary for the job. So what exactly is happening to cause
this?

The hypothesis is that the heavy google-cloud-sdk commands are causing memory
fragmentation in the reserved section for the CMA. This [LWN
article](https://lwn.net/Articles/635446/) describes out-of-memory conditions on
low memory devices that utilize ZRAM, which can cause fragmentation in the
reserved contiguous section of memory. The reason I suspect this is because I
can loop almost indefinitely on dumping images to disk if I never call any of
the heavier applications that take up the rest of the memory on the device.

The first approach I took was to disable zram (e.g., `systemctl disable armbian-zram-config.service`), but all of the commands fail with the limited
memory. The solution that I ended up going with was to reduce the resolution to
1080p and use more frames to get a brighter image. After the script runs, I
reboot the device to ensure that fragmentation does not pose any issues. The
reboot in cron is incredibly hacky, but I don't have the means to make more
extensive modifications to the device since it's the only PineCube I own. I want
to start collecting long-term data now, and every day that it doesn't run is
another day that I don't have for my time-lapse.

One thing to note is that you should use the full path to the reboot script for
it to run in the crontab. I fell victim to several failures in the job because I
had no way of telling whether the reboot ran successfully other than looking for
an image in my cloud storage bucket on the top of the hour. As a result, it
delayed the system from coming online for almost a whole day.

```bash
# m h  dom mon dow   command
0 * * * * /home/anthony/photo.sh; date >> /home/anthony/cronlogs; /usr/sbin/reboot
```

I decided to stop twiddling with the setup at this point. I feel comfortable
with rebooting the device frequently; it may cause a bit of wear on the SD card,
but it allows for these higher resolution photos without having to delve any
deeper into the specifics of the kernel/operating system. I bought a second
PineCube after dealing with all of this trouble because having another board
would allow me to test the device without fiddling with my "production" device.
There are obvious camera driver and memory allocation issues that I could try to
tackle. It could require patches to the kernel, which would be time-consuming
but an exciting endeavor.

What I thought would be a simple change to increase the resolution from 720p to
5 megapixels ended up taking several days instead, where I had to compromise
with 1080p images that required a system reboot in between because of memory
fragmentation issues. I'm not sure whether it was worth the change since the
camera has to be physically further away to have everything within frame, which
causes the image to be darker. At the very least, I'm happy with the quality of
the images in storage now.

<div style="max-width: 400px">
<img src="assets/2021-09-12/sundew-crop-norm-20210913.png" alt="cropped plant">
</div>
<i><b>Figured:</b> A cropped 1080p photo of the sundew with Contrast Limited Adaptive Histogram Equalization. Without equalization, the image would be far too dark to make out the smaller plants.</i>
