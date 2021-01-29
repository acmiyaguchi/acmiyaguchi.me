import * as posts from "./_posts/*";

export function get(req, res, next) {
  console.log(posts);
}
