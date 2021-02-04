# Precompiled plotly.js es module

This exists because of
[plotly/plotly.js#3518](https://github.com/plotly/plotly.js/issues/3518) and
issues using the precompiled library. This resolves underlying issues with d3v3
as per the issue. This would work fine in a top-level application, but plotly
also increases build time from 1 second to 8-9 seconds. This is a painful build
time for development.
