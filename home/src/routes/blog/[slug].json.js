import posts from "./_posts/*";
import path from "path";

export function get(req, res, next) {
  const { slug } = req.params;
  let post = posts.find((p) => slug == path.basename(p.path).split(".svx")[0]);
  res.end(
    JSON.stringify({
      content: post.exports.default.render(),
      metadata: post.exports.metadata,
    })
  );
}
