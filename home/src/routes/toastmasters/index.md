<script context="module">
  export async function preload() {
    let resp = await this.fetch("api/v1/blog-posts.json");
    let posts = await resp.json();
    return { metadata: posts.filter(p => p.category == "Toastmasters") };
  }
</script>

<script>
    import Speeches from "./speeches.md";
    import PostListing from "../../components/PostListing.svelte";
    export let metadata;
</script>

# Toastmasters

I'm a member of [Mountain View Toastmasters][mvtm], a club that has helped me
become a more confident public speaker. I have been working through a series of
projects on [my Innovative Planning Pathway][pathway]. Come [join us on
Zoom][meetup] during the COVID-19 pandemic.

## Blog Posts

I wrote a series of blog posts during February 2021 about my Toastmasters
experience, from speech writing to roles for a project titled "Write a
Compelling Blog ." I continue to write about Toastmasters occasionally.

<PostListing {metadata} />

[mvtm]: https://www.toastmasters.org/Find-a-Club/04528013-mountain-view-toastmasters
[meetup]: https://www.meetup.com/Mountain-View-Toastmasters/
[pathway]: https://www.toastmasters.org/pathways-overview

<Speeches />
