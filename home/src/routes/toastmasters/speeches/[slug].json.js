import posts from "./*.md";
import path from "path";

export function get(req, res, next) {
  const { slug } = req.params;
  let post = posts.find((p) => slug == path.basename(p.path).split(".md")[0]);
  res.end(JSON.stringify({ metadata: post.exports.metadata }));
}
