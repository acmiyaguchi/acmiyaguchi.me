import { blogPosts } from "../api/v1/blog-posts.json";
import dayjs from "dayjs";

// https://www.mnot.net/rss/tutorial/
// https://validator.w3.org/feed/docs/rss2.html
// https://maxschmitt.me/posts/xml-rss-feed-node-js/
export async function get(req, res, next) {
  let posts = blogPosts();
  let base = "https://acmiyaguchi.me/blog";
  let data = `
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
  <atom:link href="${base}/rss.xml" rel="self" type="application/rss+xml" />
  <title>Anthony Miyaguchi's Blog</title>
  <link>${base}</link>
  <description>Miscellaneous personal and technical writings</description>
  ${posts
    .map((post) => {
      return `
          <item>
              <title>${post.title}</title>
              <link>${base}/${post.name}</link>
              <guid>${base}/${post.name}</guid>
              <pubDate>${dayjs(post.date).format(
                "ddd, DD MMM YYYY HH:mm:ss ZZ"
              )}</pubDate>
          </item>
      `;
    })
    .join("")}
</channel>
</rss>
  `;
  res.setHeader("content-type", "application/rss+xml");
  res.end(data);
}
