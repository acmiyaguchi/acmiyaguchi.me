import posts from "./_posts/*";

export function get(req, res, next) {
  const { slug } = req.params;
  let post = posts.find((p) => slug == p.metadata.title);
  res.end(
    JSON.stringify({ content: post.default.render(), metadata: post.metadata })
  );
}
