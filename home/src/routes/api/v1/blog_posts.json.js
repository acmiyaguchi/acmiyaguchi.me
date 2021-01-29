import posts from "../../blog/_posts/*";

export function get(req, res, next) {
  res.end(JSON.stringify(posts.map((p) => p.metadata)));
}
