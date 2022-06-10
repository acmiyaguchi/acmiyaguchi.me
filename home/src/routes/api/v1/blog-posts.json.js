import posts from "../../blog/*.md";
import path from "path";
import { sortBy } from "lodash";

function blogPosts() {
  return sortBy(
    posts.map((p) => {
      let metadata = p.exports.metadata;
      // inject the path name into the metadata
      metadata.name = path.basename(p.path).split(".md")[0];
      return metadata;
    }),
    ["date"]
  ).reverse();
}

function get(req, res, next) {
  res.end(JSON.stringify(blogPosts()));
}

export { get, blogPosts };
